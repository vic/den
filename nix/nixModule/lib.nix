{
  lib,
  config,
  den-lib,
  ...
}:
{
  config.den.lib = den-lib;
  options.den.lib = lib.mkOption {
    internal = true;
    visible = false;
    type = lib.types.attrsOf lib.types.raw;
  };
}
