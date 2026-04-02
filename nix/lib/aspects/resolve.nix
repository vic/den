{ lib, ... }:
let

  resolve =
    class: aspect-chain: aspect:
    let
      provided = if lib.isFunction aspect then aspect { inherit class aspect-chain; } else aspect;

      next-chain = aspect-chain ++ [ provided ];

      imports =
        (lib.optional (provided ? ${class}) provided.${class})
        ++ (map (resolve class next-chain) (provided.includes or [ ]));

    in
    {
      inherit imports;
    };

in
class: aspect: resolve class [ aspect ] aspect
