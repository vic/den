# creates den.default aspect
{ lib, den, ... }:
{
  config.den.default.__functor = den.lib.parametric true;
  options.den.default = lib.mkOption {
    type = den.lib.aspects.types.aspectSubmodule;
  };
}
