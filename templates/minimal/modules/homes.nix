{ den, ... }:
{
  # Define standalone homes.
  # den.homes.x86_64-linux.alice = {};

  # Enable home-manager for NixOS/Darwin
  den.default.includes = [ den._.home-manager ];

  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
