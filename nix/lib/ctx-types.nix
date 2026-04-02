{ lib, den, ... }:
ctxApply:
let

  intoType =
    let
      intoAttrsType = lib.types.lazyAttrsOf lib.types.raw;
      intoFnType = lib.types.functionTo (lib.types.lazyAttrsOf lib.types.raw);
    in
    lib.types.either intoFnType intoAttrsType;

  applyIntoNode =
    ctxValue: v:
    if lib.isFunction v then
      (den.lib.take.atLeast v) ctxValue
    else if builtins.isAttrs v then
      lib.mapAttrs (_: applyIntoNode ctxValue) v
    else
      v;

  normalizeInto =
    value:
    if lib.isFunction value then value else ctxValue: lib.mapAttrs (_: applyIntoNode ctxValue) value;

  ctxSubmodule = lib.types.submodule {
    imports = den.lib.aspects.types.aspectSubmodule.getSubModules;
    options.into = lib.mkOption {
      description = "Context transformations to other context types";
      type = intoType;
      defaultText = lib.literalExpression "_: { }";
      default = _: { };
      apply = normalizeInto;
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
