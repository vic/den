{ config, lib, ... }:
{
  config._module.args.den = config.den;
  options.den.aspects = lib.mkOption {
    description = "Den Aspects";
    type = config.den.lib.aspects.types.aspectsType;
    default = { };
  };
}
