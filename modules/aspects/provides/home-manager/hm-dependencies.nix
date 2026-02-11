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
    let
      inherit (HM-OS-USER) OS HM;
      hostCtx = { inherit (HM-OS-USER) OS host user; };
      userCtx = { inherit (HM-OS-USER) HM host user; };
    in
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (parametric.fixedTo hostCtx OS)
        (parametric.fixedTo userCtx HM)
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
