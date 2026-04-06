{ lib, den, ... }:
let

  inherit (den.lib) canTake take;

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

  resolve =
    class: prev-chain: provided:
    let
      aspect = apply provided { inherit class aspect-chain; };

      aspect-chain = prev-chain ++ [ provided ] ++ (lib.optional (provided != aspect) aspect);

      classModule = lib.optional (aspect ? ${class}) (
        lib.setDefaultModuleLocation "${class}@${aspect.name}" aspect.${class}
      );

      imports = classModule ++ (map (resolve class aspect-chain) (aspect.includes or [ ]));
    in
    {
      inherit imports;
    };

in
class: aspect: resolve class [ ] aspect
