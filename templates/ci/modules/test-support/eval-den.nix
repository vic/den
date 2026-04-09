{ inputs, ... }:
{
  imports = [
    inputs.den.flakeModules.denTest
    inputs.den.flakeOutputs.flake
  ];
}
