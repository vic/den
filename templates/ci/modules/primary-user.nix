{ den, ... }:
{
  den.aspects.alice.includes = [
    # alice is always admin in all its hosts
    den._.primary-user
  ];

  den.aspects.will.includes = [
    # will is primary user in WSL NixOS.
    den._.primary-user
  ];

  perSystem =
    {
      checkCond,
      honeycrisp,
      adelie,
      ...
    }:
    {
      checks.alice-primary-on-macos = checkCond "den._.primary-user sets macos primary" (
        honeycrisp.config.system.primaryUser == "alice"
      );

      checks.will-is-wsl-default = checkCond "wsl.defaultUser defined" (
        adelie.config.wsl.defaultUser == "will"
      );
    };
}
