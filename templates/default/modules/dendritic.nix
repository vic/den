{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];
}
