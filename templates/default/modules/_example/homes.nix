# Example standalone home-manager configurations.
# These are independent of any host configuration.
# See documentation at <den>/nix/types.nix
{
  den.homes.x86_64-linux.alice = { };
  den.homes.aarch64-darwin.bob = {
    userName = "robert";
    aspect = "developer";
  };

  # move these inputs to any module you want.
  # they are here for all our examples to work on CI.
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

}
