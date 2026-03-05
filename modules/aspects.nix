{ config, lib, ... }:
let
  inherit (config.den.lib.aspects.types) aspectsType;
  denfulType = lib.types.attrsOf aspectsType;
in
{
  options.den.ful = lib.mkOption {
    default = { }; # namespaces (local or merged from inputs)
    type = denfulType;
  };
  options.flake.denful = lib.mkOption {
    default = { }; # flake output (assigned via den.namespace)
    type = lib.types.attrsOf lib.types.raw;
  };
}
