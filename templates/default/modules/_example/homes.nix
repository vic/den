# Example standalone home-manager configurations.
# These are independent of any host configuration.
# See documentation at <den>/nix/types.nix
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.homes.x86_64-linux.alice = { };
  den.homes.aarch64-darwin.bob = {
    userName = "robert";
    aspect = "developer";
  };
}
