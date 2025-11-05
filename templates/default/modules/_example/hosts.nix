# This is a fully working example configuration.
# Feel free to remove it, adapt or split into several modules.
# See documentation at <den>/nix/types.nix
{ inputs, ... }:
{
  den.hosts.aarch64-darwin.honeycrisp.users.alice = { };

  den.hosts.aarch64-linux.emperor.users.alice = { };

  den.hosts.x86_64-linux = {
    rockhopper = {
      description = "rockhopper is a kind of penguin";
      users.alice = { };
    };

    adelie = {
      description = "wsl on windows";
      users.will = { };
      intoAttr = "wslConfigurations";
      # custom nixpkgs channel.
      instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
      # custom attribute (see home-manager.nix)
      hm-module = inputs.home-manager-stable.nixosModules.home-manager;
      # custom attribute (see primary-user.nix)
      wsl = { };
    };
  };

  # move these inputs to any module you want.
  # they are here for all our examples to work on CI.
  flake-file.inputs = {

    # these stable inputs are for wsl
    nixpkgs-stable.url = "github:nixos/nixpkgs/release-25.05";
    home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.flake-compat.follows = "";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

}
