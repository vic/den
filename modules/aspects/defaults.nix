{ den, lib, ... }:
{
  options.den.default = lib.mkOption {
    description = "Default aspect";
    type = den.lib.aspects.types.aspectSubmodule;
  };
  config.den.ctx.default = den.default;
}
