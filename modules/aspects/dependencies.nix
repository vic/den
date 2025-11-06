# create aspect dependencies from hosts/users
{
  lib,
  den,
  ...
}:
let
  inherit (den.lib.dependencies) homeAspect hostAspect userAspect;

  hosts = lib.flatten (map builtins.attrValues (builtins.attrValues den.hosts));
  homes = lib.flatten (map builtins.attrValues (builtins.attrValues den.homes));

  homeDeps = map homeAspect homes;
  hostDeps = map hostAspect hosts;
  userDeps = lib.pipe hosts [
    (map (h: builtins.attrValues h.users))
    (lib.flatten)
    (lib.unique)
    (map userAspect)
  ];

  deps = hostDeps ++ userDeps ++ homeDeps;

in
{
  config.den.aspects = lib.mkMerge (lib.flatten deps);
}
