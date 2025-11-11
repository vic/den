{
  den,
  lib,
  ...
}:
let
  inherit (den.lib)
    owned
    statics
    parametric
    ;

  inherit (den.lib.take) exactly;

  dependencies = [
    (exactly ({ home }: baseDeps home))
    (exactly ({ host }: baseDeps host))
    (exactly ({ user }: baseDeps user))
    (exactly osDependencies)
    (exactly hmDependencies)
  ];

  baseDeps =
    from:
    let
      exists = from ? aspect && builtins.hasAttr from.aspect den.aspects;
      aspect = den.aspects.${from.aspect};
    in
    {
      includes = lib.optionals exists [
        (statics den.default)
        (statics aspect)
        (owned den.default)
        (owned aspect)
      ];
    };

  from = o: (lib.flip parametric) den.aspects.${o.aspect};

  osDependencies =
    { OS }:
    let
      inherit (OS) host;
      users = builtins.attrValues host.users;
      hostIncludes = [
        (from host { inherit host; })
        (from host {
          inherit OS host;
          fromHost = host;
        })
      ];
      userIncludes = user: [
        (from user { inherit user; })
        (from user {
          inherit OS user host;
          fromUser = user;
        })
        (from host {
          inherit OS user host;
          fromHost = host;
        })
      ];
    in
    {
      includes = hostIncludes ++ (map (u: { includes = userIncludes u; }) users);
    };

  hmDependencies =
    { HM }:
    let
      inherit (HM) user host;
      hostIncludes = [
        (from host { inherit host; })
        (from host {
          inherit HM user host;
          fromHost = host;
        })
      ];
      userIncludes = [
        (from user { inherit user; })
        (from user {
          inherit HM user host;
          fromUser = user;
        })
      ];
    in
    {
      includes = hostIncludes ++ userIncludes;
    };
in
{
  den.default.includes = dependencies;
}
