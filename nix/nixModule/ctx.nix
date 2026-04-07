{ den, lib, ... }:
let
  denCtxApply = den.lib.ctxApply den.ctx;
  inherit (den.lib.ctxTypes denCtxApply) ctxTreeType;

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    defaultText = lib.literalExpression "{ }";
    type = lib.types.lazyAttrsOf ctxTreeType;
  };
}
