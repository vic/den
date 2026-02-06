{ lib, ... }:
let
  # Example: configuration that depends on both host and user. provides only to HM.
  host-to-user-conditional =
    {
      user,
      host,
      ...
    }:
    if user.userName == "alice" && !lib.hasSuffix "darwin" host.system then
      {
        homeManager.programs.git.enable = true;
      }
    else
      { };
in
{

  den.aspects.rockhopper.includes = [
    # Example: host provides parametric user configuration.
    host-to-user-conditional
  ];

  perSystem =
    {
      checkCond,
      alice-at-rockhopper,
      alice-at-honeycrisp,
      ...
    }:
    {

      checks.alice-hm-git-enabled-on = checkCond "home-managed git for alice at rockhopper" (
        alice-at-rockhopper.programs.git.enable
      );
      checks.alice-hm-git-enabled-off = checkCond "home-managed git for alice at honeycrisp" (
        !alice-at-honeycrisp.programs.git.enable
      );

    };

}
