{ den, ... }:
{
  # see batteries/home-manager.nix
  den.default.includes = [ den._.home-manager ];

  # enable home-manager dependency.
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

}
