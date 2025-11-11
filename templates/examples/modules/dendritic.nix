{ inputs, lib, ... }:
{
  flake-file.inputs.flake-file.url = lib.mkDefault "github:vic/flake-file";
  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];
}
