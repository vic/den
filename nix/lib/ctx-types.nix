{ lib, den, ... }:
ctxApply:
let

  fanoutType = lib.types.listOf lib.types.raw;
  targetType = lib.types.either fanoutType (lib.types.lazyAttrsOf targetType);
  fnType = lib.types.functionTo (lib.types.lazyAttrsOf targetType);
  attrsType = lib.types.lazyAttrsOf (lib.types.functionTo targetType);
  eitherType = lib.types.either fnType attrsType;

  intoCtxType = lib.types.mkOptionType {
    name = "into";
    description = "context transformations";
    check = eitherType.check;
    merge =
      loc: defs:
      (fnType).merge loc (
        map (
          d:
          d
          // {
            value = normalize d.value;
          }
        ) defs
      );
  };

  normalize = def: if lib.isFunction def then def else ctx: builtins.mapAttrs (_: apply ctx) def;

  apply =
    ctx: v:
    if lib.isFunction v then
      (den.lib.take.atLeast v) ctx
    else if builtins.isAttrs v then
      lib.mapAttrs (_: apply ctx) v
    else
      v;

  ctxSubmodule = lib.types.submodule {
    imports = den.lib.aspects.types.aspectSubmodule.getSubModules;
    options.into = lib.mkOption {
      description = "Context transformations to other context types";
      type = intoCtxType;
      defaultText = lib.literalExpression "_: { }";
      default = _: { };
      apply = normalize;
    };
    config.__functor = lib.mkForce ctxApply;
  };

  ctxTreeType = lib.types.mkOptionType {
    name = "ctxTree";
    description = "ctx definition or namespace";
    check = lib.isAttrs;
    merge =
      loc: defs:
      let
        ctxNodeKeys = [
          "into"
          "provides"
          "_"
          "includes"
          "__functor"
          "_module"
        ];
        hasKey = x: builtins.any (k: x ? ${k}) ctxNodeKeys;
        isLeaf = lib.any (d: hasKey d.value) defs;
      in
      if isLeaf then ctxSubmodule.merge loc defs else (lib.types.lazyAttrsOf ctxTreeType).merge loc defs;
    emptyValue = {
      value = { };
    };
  };

in
{
  inherit ctxTreeType;
}
