{ lib, den, ... }:
{
  init =
    fx:
    let
      adapters = import ./adapters.nix { inherit lib den fx; };
      aspect = import ./aspect.nix { inherit lib den fx; };
      handlers = import ./handlers.nix { inherit lib den fx; };
      ctxApply = import ./ctx-apply.nix {
        inherit
          lib
          den
          fx
          adapters
          ;
      };
      resolve = import ./resolve.nix {
        inherit
          lib
          den
          fx
          aspect
          handlers
          adapters
          ctxApply
          ;
      };
    in
    {
      inherit (aspect) wrapAspect;
      inherit (handlers)
        parametricHandler
        staticHandler
        contextHandlers
        missingArgError
        ctxSeenHandler
        ctxProviderHandler
        ctxTraverseHandler
        ctxTraceHandler
        ;
      inherit (resolve)
        resolveOne
        resolveOneStrict
        resolveDeep
        resolveDeepEffectful
        fxFullResolve
        fxResolve
        mkPipeline
        defaultHandlers
        defaultState
        composeHandlers
        wrapIdentity
        ;
      inherit ctxApply;
      inherit
        adapters
        aspect
        handlers
        resolve
        ;
    };
}
