{ lib, den, ... }:
let

  inherit (den.lib) canTake take;

  resolve =
    class: prev-chain: provided:
    let
      aspect = if canTake.upTo args provided then take.upTo provided args else provided;

      aspect-chain = prev-chain ++ [ provided ] ++ (lib.optional (provided != aspect) aspect);

      args = {
        inherit aspect class aspect-chain;
      };

      imports =
        (lib.optional (aspect ? ${class}) aspect.${class})
        ++ (map (resolve class aspect-chain) (aspect.includes or [ ]));

    in
    {
      inherit imports;
    };

in
class: aspect: resolve class [ ] aspect
