{ den, lib, ... }:
{
  options.den.default = lib.mkOption {
    description = "Default aspect";
    type = den.lib.aspects.types.aspectType;
  };
  config.den.ctx.default = den.default;
}
