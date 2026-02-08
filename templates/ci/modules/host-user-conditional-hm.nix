{ lib, ... }:
let
  # Example: configuration that depends on both host and user. provides only to HM.
  program-conditional =
    program:
    {
      user,
      host,
      ...
    }:
    if user.userName == "alice" && !lib.hasSuffix "darwin" host.system then
      {
        homeManager.programs.${program}.enable = true;
      }
    else
      { };
in
{

  # Example: host parametric includes. conditional user configuration.
  den.aspects.rockhopper.includes = [ (program-conditional "git") ];

  # Example: user parametric includes
  den.aspects.alice.includes = [ (program-conditional "mpv") ];

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

      checks.alice-hm-mpv-enabled-rockhopper = checkCond "home-managed mpv for alice at rockhopper" (
        alice-at-rockhopper.programs.mpv.enable
      );

    };

}
