{
  lib,
  inputs,
  config,
  ...
}:
{
  config.den.lib = inputs.den.lib { inherit inputs lib config; };
  options.den.lib = lib.mkOption {
    internal = true;
    visible = false;
    type = lib.types.attrsOf lib.types.raw;
  };
}
