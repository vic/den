{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  imports = [ inputs.nix-unit.modules.flake.default ];

  perSystem.nix-unit.allowNetwork = true;
  perSystem.nix-unit.inputs = inputs;
}
