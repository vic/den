# DO-NOT-EDIT: nix-unit configuration.
{ lib, inputs, ... }:
{
  perSystem.nix-unit = {
    allowNetwork = lib.mkDefault true;
    inputs = lib.mkDefault inputs;
  };
}
