{
  # globally enable fish on all homes ever.
  den.default.homeManager.programs.fish.enable = true;

  perSystem =
    { checkCond, alice-at-rockhopper, ... }:
    {
      checks.alice-hm-fish-enabled-by-default = checkCond "home-managed fish for alice" (
        alice-at-rockhopper.programs.fish.enable
      );
    };
}
