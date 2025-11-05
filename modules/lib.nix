{
  lib,
  inputs,
  ...
}:
{
  config.den.lib = inputs.den.lib lib inputs;
  options.den.lib = lib.mkOption {
    internal = true;
    visible = false;
    type = lib.types.attrsOf lib.types.raw;
  };
}
