{
  # Example: user provides static config to all its nixos hosts.
  den.aspects.alice.nixos.users.users.alice.description = "Alice Q. User";

  perSystem =
    { checkCond, rockhopper, ... }:
    {
      checks.user-contributes-to-host = checkCond "alice.nixos sets on rockhopper host" (
        rockhopper.config.users.users.alice.description == "Alice Q. User"
      );
    };
}
