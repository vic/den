# create aspect dependencies from hosts/users
{
  lib,
  den,
  ...
}:
let
  # creates den.aspects.${host.aspect}
  hostAspect =
    host:
    { aspects, ... }:
    {
      ${host.aspect} = {
        ${host.class} = { };
        includes = [
          den.default
          (userContribsToHost aspects)
        ];
        __functor = den.lib.parametric { inherit host; };
      };
    };

  # creates aspects.${user.aspect}
  userAspect =
    user:
    { aspects, ... }:
    {
      ${user.aspect} = {
        ${user.class} = { };
        includes = [
          den.default
          (hostContribsToUser aspects)
        ];
        __functor = den.lib.parametric true;
      };
    };

  # creates den.aspects.${home.aspect}
  homeAspect = home: {
    ${home.aspect} = {
      ${home.class} = { };
      includes = [ den.default ];
      __functor = den.lib.parametric { inherit home; };
    };
  };

  userContribsToHost =
    aspects:
    { host }:
    {
      includes =
        let
          users = lib.attrValues host.users;
          userContribs = user: aspects.${user.aspect} { inherit host user; };
        in
        map userContribs users;
    };

  hostContribsToUser =
    aspects:
    # deadnix: skip
    { user, host }:
    aspects.${host.aspect}
    // {
      __functor = den.lib.parametric { inherit user host; };
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
  config.den.aspects = lib.mkMerge (lib.flatten deps);
}
