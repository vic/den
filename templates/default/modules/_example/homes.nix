# Example standalone home-manager configurations.
# These are independent of any host configuration.
# See documentation at <den>/nix/types.nix
{
  den.homes.x86_64-linux.alice = { };
  den.homes.aarch64-darwin.bob = {
    userName = "robert";
    aspect = "developer";
  };
}
