{ den, ... }:
{
  den.default.includes = [
    # Example: parametric over many contexts: { home }, { host, user }, { fromUser, toHost }
    den.provides.define-user
  ];

  perSystem =
    {
      checkCond,
      rockhopper,
      adelie,
      ...
    }:
    {

      checks.alice-exists-on-rockhopper = checkCond "den.default.user.includes defines user on host" (
        rockhopper.config.users.users.alice.isNormalUser
      );
      checks.alice-not-exists-on-adelie = checkCond "den.default.user.includes defines user on host" (
        !adelie.config.users.users ? alice
      );
      checks.will-exists-on-adelie = checkCond "den.default.user.includes defines user on host" (
        adelie.config.users.users.will.isNormalUser
      );
    };
}
