{
  den,
  ...
}:
let
  inherit (den.lib)
    owned
    statics
    parametric
    take
    ;

  dependencies = [
    (take.exactly hmUserDependencies)
    (take.exactly hmStandaloneDependencies)
  ];

  # from OS home-managed integration.
  hmUserDependencies =
    { HM-OS-USER }:
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (parametric.fixedTo HM-OS-USER HM-OS-USER.OS)
        (parametric.fixedTo HM-OS-USER HM-OS-USER.HM)
      ];
    };

  hmStandaloneDependencies =
    { HM, home }:
    take.unused home {
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
