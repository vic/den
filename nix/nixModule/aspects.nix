{ config, lib, ... }:
let
  inherit (config.den.lib.aspects.types) aspectsType;
in
{
  options.den.aspects = lib.mkOption {
    description = "Den Aspects";
    default = { };
    type = aspectsType;
  };
}
