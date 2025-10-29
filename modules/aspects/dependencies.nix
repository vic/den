# create aspect dependencies from hosts/users
{
  lib,
  config,
  den,
  ...
}:
let
  hosts = lib.flatten (map builtins.attrValues (builtins.attrValues config.den.hosts));
  homes = lib.flatten (map builtins.attrValues (builtins.attrValues config.den.homes));

  # creates den.aspects.${host.aspect}
  #
  # ${host.aspect} invokes ${host.aspect}._.host.includes with { host }
  # - den.default.host is in this list.
  hostAspect = host: {
    ${host.aspect} =
      { aspect, ... }:
      {
        ${host.class} = { };
        includes = map (f: f { inherit host; }) aspect._.host.includes;
        _.host.includes = [ den.default.host ];
      };
  };

  # creates aspects.${user.aspect}
  #
  # ${user.aspect} invokes ${user.aspect}._.user.includes with { host, user }
  # - den.default.user is in this list.
  #
  # ${host.aspect} depends on:
  #   - aspects.${user.aspect}.provides.${host.aspect} { host, user }
  #   - aspects.${user.aspect}.provides.hostUser { host, user }
  #   - den.default.user.provides.hostUser { host, user }
  hostUserAspect =
    host: user:
    { aspects, ... }:
    let
      context = { inherit host user; };
      empty =
        # deadnix: skip
        { host, user }: _: { };
    in
    {
      ${user.aspect} =
        { aspect, ... }:
        {
          ${user.class} = { };
          includes = map (f: f context) aspect._.user.includes;
          _.user.includes = [ den.default.user ];
        };

      ${host.aspect}.includes = map (f: f context) [
        (aspects.${user.aspect}.provides.${host.aspect} or empty)
        (aspects.${user.aspect}.provides.hostUser or empty)
        (den.default.user.provides.hostUser or empty)
      ];
    };

  # creates den.aspects.${home.aspect}
  #
  # ${home.aspect} invokes ${home.aspect}._.home.includes with { home }
  # - den.default.home is in this list.
  homeAspect = home: {
    ${home.aspect} =
      { aspect, ... }:
      {
        ${home.class} = { };
        includes = map (f: f { inherit home; }) aspect._.home.includes;
        _.home.includes = [ den.default.home ];
      };
  };

  hostDeps = map (host: [
    (hostAspect host)
    (map (hostUserAspect host) (builtins.attrValues host.users))
  ]) hosts;

  homeDeps = map homeAspect homes;

  deps = hostDeps ++ homeDeps;

in
{
  config.den.aspects = lib.mkMerge (lib.flatten deps);
}
