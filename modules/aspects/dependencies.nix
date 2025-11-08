{
  den,
  ...
}:
let
  inherit (den.lib) owned statics;

  dependencies = [
    # owned attributes: <aspect>.<class>
    ({ home, ... }: owned home.class den.aspects.${home.aspect})
    ({ host, ... }: owned host.class den.aspects.${host.aspect})
    ({ user, ... }: owned user.class den.aspects.${user.aspect})

    # defaults: owned from den.default.<class>
    ({ home, ... }: owned home.class den.default)
    ({ host, ... }: owned host.class den.default)
    ({ user, ... }: owned user.class den.default)

    # static (non-parametric) from <aspect>.includes
    ({ home, ... }: statics den.aspects.${home.aspect})
    ({ host, ... }: statics den.aspects.${host.aspect})
    ({ user, ... }: statics den.aspects.${user.aspect})

    # user-to-host context
    ({ fromUser, toHost }: owned toHost.class den.aspects.${fromUser.aspect})
    # host-to-user context
    ({ fromHost, toUser }: owned toUser.class den.aspects.${fromHost.aspect})

    # { host } => [ { fromUser, toHost } ]
    (hostIncludesFromUsers)

    # { user, host } => { fromHost, toUser }
    (userIncludesFromHost)
  ];

  hostIncludesFromUsers =
    { host, ... }:
    {
      includes =
        let
          users = builtins.attrValues host.users;
          context = user: {
            fromUser = user;
            toHost = host;
          };
          contrib = user: den.aspects.${user.aspect} (context user);
        in
        map contrib users;
    };

  userIncludesFromHost =
    { user, host }:
    {
      includes = den.aspects.${host.aspect}.includes;
      __functor = den.lib.parametric {
        fromHost = host;
        toUser = user;
      };
    };

in
{
  den.default.includes = dependencies;
}
