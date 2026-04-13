{ lib, den, ... }:
{
  init =
    fx:
    let
      adapters = import ./adapters.nix { inherit lib den fx; };
      aspect = import ./aspect.nix { inherit lib den fx; };
      handlers = import ./handlers.nix { inherit lib den fx; };
      resolve = import ./resolve.nix {
        inherit
          lib
          den
          fx
          aspect
          handlers
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
        ;
      inherit (resolve)
        resolveOne
        resolveOneStrict
        resolveDeep
        wrapIdentity
        ;
      inherit
        adapters
        aspect
        handlers
        resolve
        ;
    };
}
