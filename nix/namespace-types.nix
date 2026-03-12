{ den, lib, ... }:
let
  inherit (den.lib) take parametric ctxApply;
  inherit (den.lib.aspects.types) aspectsType aspectSubmodule;

  namespaceType = lib.types.submodule (
    nsArgs:
    let
      nsCtxApply = ctxApply nsArgs.config.ctx;
      inherit (den.lib.ctxTypes nsCtxApply) ctxTreeType;
    in
    {
      options.ctx = lib.mkOption {
        description = "namespace context pipeline";
        default = { };
        type = lib.types.lazyAttrsOf ctxTreeType;
      };
      options.schema = lib.mkOption {
        description = "namespace schema — freeform deferred modules per entity kind";
        default = { };
        type = lib.types.submodule {
          freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
        };
      };
      freeformType = aspectsType;
    }
  );
in
{
  inherit namespaceType;
}
