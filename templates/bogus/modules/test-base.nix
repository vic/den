# DO NOT EDIT.
{ inputs, lib, ... }:
{
  imports = [
    inputs.den.flakeModules.denTest
    inputs.nix-unit.modules.flake.default
  ];
  denTest.imports = [ inputs.den.flakeOutputs.flake ];
  systems = lib.systems.flakeExposed;
  perSystem.nix-unit = {
    allowNetwork = lib.mkDefault true;
    inputs = lib.mkDefault inputs;
  };
}
