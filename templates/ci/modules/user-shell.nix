{ den, lib, ... }:
{

  den.aspects.will.includes = [
    # will has always loved red snappers
    (den._.user-shell "fish")
  ];

  perSystem =
    { checkCond, adelie, ... }:
    {
      checks.will-always-love-you = checkCond "red-snapper fish is default shell" (
        "fish" == lib.getName adelie.config.users.users.will.shell
      );
    };

}
