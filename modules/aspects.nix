{ den, lib, ... }:
{
  options.den.ful = lib.mkOption {
    default = { };
    type = lib.types.attrsOf den.lib.nsTypes.namespaceType;
  };
  options.flake.denful = lib.mkOption {
    default = { };
    type = lib.types.attrsOf lib.types.raw;
  };
}
