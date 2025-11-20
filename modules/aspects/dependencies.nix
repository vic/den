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
              contrib = osUserDependencies { inherit OS host; };
            in
            map contrib users;
        }
      ];
    };

  osUserDependencies =
    { OS, host }:
    user:
    let
      USR = den.aspects.${user.aspect};
    in
    {
      includes = [
        (owned USR)
        (statics USR)
        (USR { inherit OS host user; })
      ];
    };

  # from OS home-managed integration.
  hmUserDependencies =
    {
      OS-HM,
      host,
      user,
    }:
    let
      inherit (OS-HM) OS HM;
      context = {
        inherit
          OS
          HM
          user
          host
          ;
      };
    in
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (owned HM)
        (statics HM)
        (parametric.fixedTo context OS)
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
