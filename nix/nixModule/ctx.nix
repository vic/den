{ config, lib, ... }:
let
  inherit (config) den;
  inherit (den.lib.aspects.types) aspectSubmodule;
  inherit (den.lib) ctxApply;

  intoType =
    let
      # into = { x = {ctx}: []; y = {ctx}: []}; }
      intoAttrsType = lib.types.lazyAttrsOf (lib.types.functionTo (lib.types.listOf lib.types.raw));

      # into = {ctx}: { x = []; y = []; }
      intoFnType = lib.types.functionTo (lib.types.lazyAttrsOf lib.types.raw);
    in
    lib.types.either intoFnType intoAttrsType;

  normalizeInto =
    value:
    if lib.isFunction value then
      value
    else
      ctx: lib.mapAttrs (n: v: (den.lib.take.atLeast v) ctx) value;

  # a context-definiton is an aspect extended with into.* transformations
  # and a fixed functor to apply them.
  ctxSubmodule = lib.types.submodule (
    { config, ... }:
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

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    type = lib.types.lazyAttrsOf ctxSubmodule;
  };
}
