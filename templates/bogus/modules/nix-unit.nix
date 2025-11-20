# DO-NOT-EDIT: nix-unit configuration.
{ lib, inputs, ... }:
{

  flake-file.inputs.nix-unit = {
    url = "github:nix-community/nix-unit";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
  };

  imports = [
    inputs.nix-unit.modules.flake.default
  ];

  perSystem.nix-unit = {
    allowNetwork = lib.mkDefault true;
    inputs = lib.mkDefault inputs;
  };
}
