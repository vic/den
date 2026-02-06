let

  # Example: luke standalone home-manager has access to rockhopper osConfig specialArg.
  os-conditional-hm =
    { home, ... }:
    {
      # access osConfig, wired via extraSpecialArgs in homes.nix.
      homeManager =
        { osConfig, ... }:
        {
          programs.bat.enable = osConfig.programs.${home.programToDependOn}.enable;
        };
    };
in
{

  # Example: standalone-hm config depends on osConfig (non-recursive)
  # NOTE: this will only work for standalone hm, and not for hosted hm
  # since a hosted hm configuration cannot depend on the os configuration.
  den.aspects.luke.includes = [
    os-conditional-hm
  ];

  perSystem =
    { checkCond, luke, ... }:
    {
      checks.luke-hm-depends-on-osConfig = checkCond "standalone hm can depend on osConfig" (
        luke.config.programs.bat.enable
      );
    };
}
