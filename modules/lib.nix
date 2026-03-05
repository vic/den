{
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    (inputs.den.lib { inherit inputs lib config; }).nixModule
  ];
}
