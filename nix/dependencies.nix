{ parametric }:
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
        __functor = parametric { inherit host; };
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
        __functor = parametric true;
      };
    };

  # creates den.aspects.${home.aspect}
  homeAspect = home: {
    ${home.aspect} = {
      ${home.class} = { };
      includes = [ den.default ];
      __functor = parametric { inherit home; };
    };
  };

  userContribsToHost =
    aspects:
    { host }:
    {
      includes =
        let
          users = builtins.attrValues host.users;
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
      __functor = parametric { inherit user host; };
    };
in
{
  inherit homeAspect hostAspect userAspect;
}
