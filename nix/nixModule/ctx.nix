{ config, lib, ... }:
let
  inherit (config) den;
  inherit (den.lib.aspects.types) aspectSubmodule;
  inherit (den.lib) ctxApply take;

  intoType =
    let
      # into = { x = ctx→[]; y = ctx→[]; }
      # Also supports nested namespace keys: into."foo.bar" = fn
      intoAttrsType = lib.types.lazyAttrsOf lib.types.raw;

      # into = ctx → { x = []; y = []; }
      intoFnType = lib.types.functionTo (lib.types.lazyAttrsOf lib.types.raw);
    in
    lib.types.either intoFnType intoAttrsType;

  # Recrusively apply ctx to leaf functions in a (possibly nested) attrset.
  applyIntoNode =
    ctx: v:
    if lib.isFunction v then
      (take.atLeast v) ctx
    else if builtins.isAttrs v then
      lib.mapAttrs (_: applyIntoNode ctx) v
    else
      v;

  normalizeInto =
    value: if lib.isFunction value then value else ctx: lib.mapAttrs (_: applyIntoNode ctx) value;

  ctxSubmodule = lib.types.submodule (
    { ... }:
    {
      imports = aspectSubmodule.getSubModules;
      options.into = lib.mkOption {
        description = "Context transformations to other context types";
        type = intoType;
        default = _: { };
        apply = normalizeInto;
      };
      config.__functor = lib.mkForce ctxApply;
    }
  );

  # A ctx tree node: either a leaf ctx definition (has `into`/`__functor`)
  # or a namespace container holding more nodes. Detected at merge time,
  # so the self-reference in the namespace branch is lazily evaluated.
  ctxTreeType = lib.types.mkOptionType {
    name = "ctxTree";
    description = "ctx definition or namespace";
    check = lib.isAttrs;
    merge =
      loc: defs:
      let
        hasKey = x: x ? into || x ? provides || x ? _ || x ? includes || x ? __functor || x ? _module;
        isLeaf = lib.any (d: hasKey d.value) defs;
      in
      if isLeaf then ctxSubmodule.merge loc defs else (lib.types.lazyAttrsOf ctxTreeType).merge loc defs;
    emptyValue = {
      value = { };
    };
  };

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    type = lib.types.lazyAttrsOf ctxTreeType;
  };
}
