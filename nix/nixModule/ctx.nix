{ den, lib, ... }:
let
  inherit (den.lib) take;
  inherit (den.lib.aspects.types) aspectSubmodule;

  denCtxApply = den.lib.ctxApply den.ctx;
  inherit (den.lib.ctxTypes denCtxApply) ctxTreeType;

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    internal = true;
    visible = false;
    type = lib.types.lazyAttrsOf ctxTreeType;
  };
}
