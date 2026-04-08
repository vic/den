{ lib, den, ... }:
let

  inherit (den.lib) canTake take;
  inherit (den.lib.aspects) adapters;

  apply =
    provided: args:
    let
      res = if canTake.upTo args provided then take.upTo provided args else provided;
      mod =
        den.lib.aspects.types.aspectType.merge
          [ ]
          [
            {
              file = "<curried>";
              value = res;
            }
          ];
    in
    if lib.isFunction res then mod else res;

  withAdapter =
    adapter: class:
    let
      go =
        prevChain: provided:
        let
          aspect = apply provided { inherit class aspect-chain; };

          aspect-chain = prevChain ++ [ provided ] ++ (lib.optional (provided != aspect) aspect);

          classModule = lib.optional (aspect ? ${class}) (
            lib.setDefaultModuleLocation "${class}@${aspect.name or "<anon>"}" aspect.${class}
          );

          recurse = go aspect-chain;

          resolveChild =
            i:
            apply i {
              inherit class;
              aspect-chain = aspect-chain ++ [ i ];
            };
        in
        adapter {
          inherit
            aspect
            class
            classModule
            recurse
            aspect-chain
            resolveChild
            ;
        };
    in
    go [ ];

  resolve = withAdapter (adapters.filterIncludes adapters.module);

in
{
  inherit withAdapter;
  __functor = _: resolve;
}
