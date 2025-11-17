# creates den.default aspect
{ lib, den, ... }:
{
  config.den.default = den.lib.parametric.atLeast { };
  options.den.default = lib.mkOption {
    type = den.lib.aspects.types.aspectSubmodule;
  };
}
