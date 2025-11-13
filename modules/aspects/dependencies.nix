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
    (exactly osDependencies)
    (exactly hmUserDependencies)
    (exactly hmStandaloneDependencies)
  ];

  osDependencies =
    { OS, host }:
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (owned OS)
        (statics OS)
        {
          includes =
            let
              users = builtins.attrValues host.users;
              contrib = osUserDependencies OS host;
            in
            map contrib users;
        }
      ];
    };

  osUserDependencies =
    OS: host: user:
    let
      USR = den.aspects.${user.aspect};
      ctx = { inherit OS host user; };
    in
    {
      includes = [
        (owned USR)
        (statics USR)
        (USR ctx)
      ];
    };

  # from home-manager integration.
  hmUserDependencies =
    {
      HM,
      host,
      user,
    }:
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (owned HM)
        (statics HM)
        (hmOsDependencies HM host user)
      ];
    };

  hmOsDependencies =
    HM: host: user:
    let
      OS = den.aspects.${host.aspect};
      newCtx = {
        inherit
          HM
          OS
          host
          user
          ;
      };
    in
    {
      includes = [
        (owned OS)
        (statics OS)
        (parametric newCtx OS)
      ];
    };

  hmStandaloneDependencies =
    { HM, home }:
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (owned HM)
        (statics HM)
      ];
    };

in
{
  den.default.includes = dependencies;
}
