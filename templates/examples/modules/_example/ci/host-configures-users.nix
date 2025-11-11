{

  # Example: host provides static config to all its users hm.
  den.aspects.rockhopper.homeManager.programs.direnv.enable = true;

  perSystem =
    { checkCond, alice-at-rockhopper, ... }:
    {
      checks.host-contributes-to-user = checkCond "rockhopper contributes to all its users" (
        alice-at-rockhopper.programs.direnv.enable
      );
    };
}
