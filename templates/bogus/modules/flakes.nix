# DO-NOT-CHANGE. Keep your reproduction minimalistic!
#
# try not adding new inputs
# but if you have no options (pun intended)
# here's the place.
#
# IF you make any change to this file, use:
#   `nix run .#write-flake`
#
# We provide nix-darwin and home-manager for common usage.
{
  # change "main" with a commit where bug is present
  flake-file.inputs.den.url = "github:vic/den/main";

  # included so we can test HM integrations.
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # included for testing darwin hosts.
  flake-file.inputs.darwin = {
    url = "github:nix-darwin/nix-darwin";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
