# create aspect dependencies from hosts/users
{
  lib,
  den,
  ...
}:
let
  inherit (den.lib) parametric;

  makeAspect = from: {
    ${from.aspect} = parametric.atLeast {
      ${from.class} = { };
      includes = [ den.default ];
    };
  };

  hosts = map builtins.attrValues (builtins.attrValues den.hosts);
  homes = map builtins.attrValues (builtins.attrValues den.homes);
  aspectClass = from: { inherit (from) aspect class; };

  deps = lib.pipe hosts [
    (lib.flatten)
    (map (h: builtins.attrValues h.users))
    (users: users ++ hosts ++ homes)
    (lib.flatten)
    (map aspectClass)
    (lib.unique)
    (map makeAspect)
  ];
in
{
  den.aspects = lib.mkMerge deps;
}
