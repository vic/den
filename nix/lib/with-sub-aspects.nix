{ den, lib, ... }:
let

  withSubAspects =
    aspects: includes:
    assert lib.isList aspects;
    assert lib.isList includes;
    (lib.map (
      a:
      assert lib.isString a;
      lib.getAttrFromPath [ "aspects" a "provides" ] den
    ) aspects)
    ++ includes;
in
withSubAspects
