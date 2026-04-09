{ den, lib, ... }:
let
  withSubAspectsOf =
    aspects: includes:
    lib.addErrorContext "while collecting sub aspects for ${lib.join "," aspects}" (
      assert lib.isList aspects;
      assert lib.isList includes;
      (lib.map (
        aspect:
        lib.addErrorContext "while collecting sub aspect for ${aspect}" (
          assert lib.isString aspect;
          lib.getAttrFromPath [ "aspects" aspect "provides" ] den
        )
      ) aspects)
      ++ includes
    );
in
withSubAspectsOf
