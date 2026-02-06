{
  # Example: enable helix for alice on all its home-managed hosts.
  den.aspects.alice.homeManager.programs.helix.enable = true;

  perSystem =
    { checkCond, alice-at-rockhopper, ... }:
    {
      checks.alice-hm-helix-enabled-by-user = checkCond "home-managed helix for alice" (
        alice-at-rockhopper.programs.helix.enable
      );
    };

}
