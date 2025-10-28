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
  # ${host.aspect} depends on:
  #   - den.default.host and its includes list taking { host }
  hostAspect = host: {
    ${host.aspect} = {
      includes = [ (den.default.host { inherit host; }) ];
      ${host.class} = { };
    };
  };

  # creates aspects.${user.aspect}
  #
  # ${user.aspect} depends on:
  #   - den.default.user and its includes list taking { host, user }
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
      ${user.aspect} = {
        ${user.class} = { };
        includes = [ (den.default.user context) ];
      };

      ${host.aspect}.includes = [
        ((aspects.${user.aspect}.provides.${host.aspect} or empty) context)
        ((aspects.${user.aspect}.provides.hostUser or empty) context)
        ((den.default.user.provides.hostUser or empty) context)
      ];
    };

  # creates den.aspects.${home.aspect}
  #
  # ${home.aspect} depends on: den.default.home
  homeAspect = home: {
    ${home.aspect} = {
      includes = [ (den.default.home { inherit home; }) ];
      ${home.class} = { };
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
