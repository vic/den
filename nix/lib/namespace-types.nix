{ den, lib, ... }:
let
  inherit (den.lib) ctxApply;
  inherit (den.lib.aspects) mkAspectsType;

  namespaceType = lib.types.submodule (
    nsArgs@{ name, ... }:
    let
      nsCtxApply = ctxApply nsArgs.config.ctx;
      inherit (den.lib.ctxTypes nsCtxApply) ctxTreeType;
    in
    {
      options.ctx = lib.mkOption {
        description = "namespace context pipeline";
        defaultText = lib.literalExpression "{ }";
        default = { };
        type = lib.types.lazyAttrsOf ctxTreeType;
      };
      options.schema = lib.mkOption {
        description = "namespace schema — freeform deferred modules per entity kind";
        defaultText = lib.literalExpression "{ }";
        default = { };
        type = lib.types.submodule {
          freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
        };
      };
      freeformType = (mkAspectsType { providerPrefix = [ name ]; }).aspectsType;
    }
  );
in
{
  inherit namespaceType;
}
