# create aspect dependencies from hosts/users
{
  lib,
  config,
  den,
  ...
}:
let

  # creates den.aspects.${host.aspect}
  hostAspect =
    host:
    { aspects, ... }:
    {
      ${host.aspect} =
        { aspect, ... }:
        {
          name = "<host:${host.name}>";
          ${host.class} = { };
          includes = map (f: f { inherit host; }) aspect._.host.includes;
          provides.host.includes = [
            den.default.host._.host
            (hostUserContribs aspects)
          ];
        };
    };

  hostUserContribs =
    aspects:
    { host }:
    {
      name = "<host-user-contribs:${host.name}.users.*>";
      includes =
        let
          users = lib.attrValues host.users;
          userContribs = map (user: aspects.${user.aspect}._.user { inherit host; }) users;
        in
        userContribs;
    };

  # creates aspects.${user.aspect}
  userAspect = user: {
    ${user.aspect} =
      { aspect, ... }:
      {
        name = "<user:${user.name}>";
        ${user.class} = { };
        provides.user.includes = [ den.default.user._.user ];
        provides.user.__functor =
          callbacks:
          { host }:
          {
            name = "<user:${user.name}.user.*>";
            includes = [ aspect ] ++ map (f: f { inherit user host; }) callbacks.includes;
          };
      };
  };

  # creates den.aspects.${home.aspect}
  homeAspect = home: {
    ${home.aspect} =
      { aspect, ... }:
      {
        name = "<home:${home.name}>";
        ${home.class} = { };
        includes = map (f: f { inherit home; }) aspect._.home.includes;
        provides.home.includes = [ den.default.home._.home ];
      };
  };

  hosts = lib.flatten (map builtins.attrValues (builtins.attrValues config.den.hosts));
  homes = lib.flatten (map builtins.attrValues (builtins.attrValues config.den.homes));

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
