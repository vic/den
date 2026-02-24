{ inputs, lib, ... }:
{
  systems = lib.systems.flakeExposed;

  imports = [ inputs.nix-unit.modules.flake.default ];

  perSystem.nix-unit.allowNetwork = true;
  perSystem.nix-unit.inputs = inputs;
}
