# create aspect dependencies from hosts/users
{
  lib,
  den,
  ...
}:
let
  inherit (den.lib) parametric;

  # creates den.aspects.${home.aspect}
  homeAspect = home: {
    ${home.aspect} = {
      ${home.class} = { };
      includes = [ den.default ];
      __functor = HM: parametric { inherit HM home; } HM;
    };
  };

  # creates den.aspects.${host.aspect}
  hostAspect = host: {
    ${host.aspect} = {
      ${host.class} = { };
      includes = [ den.default ];
      __functor = OS: parametric { inherit OS host; } OS;
    };
  };

  # creates aspects.${user.aspect}
  userAspect = user: {
    ${user.aspect} = {
      ${user.class} = { };
      includes = [ den.default ];
      __functor = parametric.expands { inherit user; };
    };
  };

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
  den.aspects = lib.mkMerge (lib.flatten deps);
}
