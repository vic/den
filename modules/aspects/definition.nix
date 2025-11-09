# create aspect dependencies from hosts/users
{
  lib,
  den,
  ...
}:
let
  # creates den.aspects.${home.aspect}
  homeAspect = home: {
    ${home.aspect} = {
      ${home.class} = { };
      includes = [ den.default ];
      __functor = den.lib.parametric { inherit home; };
    };
  };

  # creates den.aspects.${host.aspect}
  hostAspect = host: {
    ${host.aspect} = {
      ${host.class} = { };
      includes = [ den.default ];
      __functor = den.lib.parametric { OS = { inherit host; }; };
    };
  };

  # creates aspects.${user.aspect}
  userAspect = user: {
    ${user.aspect} = {
      ${user.class} = { };
      includes = [ den.default ];
      __functor = den.lib.parametric true;
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
