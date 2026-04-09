{ inputs, den, ... }:
{
  systems = builtins.attrNames den.hosts;

  imports = [
    inputs.den.flakeModule
    inputs.files.flakeModules.default
  ];
}
