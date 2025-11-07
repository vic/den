# DO-NOT-CHANGE. Keep your reproduction minimalistic!
#
# try not adding new inputs
# but if you have no options (pun intended)
# here's the place.
#
# IF you make any change to this file, use:
#   `nix run .#write-flake`
#
# We provide nix-unit and home-manager for common
# usage.
{ inputs, ... }:
{
  # change "main" with a commit where bug is present
  flake-file.inputs.den.url = "github:vic/den/main";

  flake-file.inputs.nix-unit = {
    url = "github:nix-community/nix-unit";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
    inputs.treefmt-nix.follows = "treefmt-nix";
  };

  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    inputs.nix-unit.modules.flake.default
  ];

}
