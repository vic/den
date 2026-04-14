{ lib, den, ... }:
let
  # Pure adapter constructors — no nix-effects dependency.
  # Available without init for use in aspect definitions.
  pureAdapters = import ./adapters.nix {
    inherit lib den;
    fx = null;
  };
in
{
  # Adapter constructors usable in aspect meta.adapter without nix-effects.
  inherit (pureAdapters)
    excludeAspect
    substituteAspect
    filterAspect
    aspectPath
    pathKey
    toPathSet
    tombstone
    ;

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
        ctxEmitHandler
        adapterRegistryHandler
        provideClassHandler
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
