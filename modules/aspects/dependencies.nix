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
    ({ userToHost, ... }: owned userToHost.host.class den.aspects.${userToHost.user.aspect})
    # host-to-user context
    ({ hostToUser, ... }: owned hostToUser.user.class den.aspects.${hostToUser.host.aspect})

    # { host } => [ { userToHost } ]
    (hostIncludesFromUsers)

    # { user, host } => { hostToUser }
    (userIncludesFromHost)
  ];

  hostIncludesFromUsers =
    { host, ... }:
    {
      includes =
        let
          users = builtins.attrValues host.users;
          context = user: {
            userToHost = {
              inherit user host;
            };
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
        hostToUser = {
          inherit host user;
        };
      };
    };

in
{
  den.default.includes = dependencies;
}
