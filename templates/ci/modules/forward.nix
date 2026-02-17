{ lib, den, ... }:
let

  oneModule.foo = [ "one" ];

  targetSubmodule = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        {
          options.foo = lib.mkOption {
            type = lib.types.listOf lib.types.str;
          };
        }
      ];
    };
  };

  forwarded =
    { class, aspect-chain }:
    den._.forward {
      each = lib.singleton class; # item ignored
      fromClass = _item: "fwd-origin";
      intoClass = _item: "nixos";
      intoPath = _item: [ "fwd-target" ];
      fromAspect = _item: lib.head aspect-chain;
    };

in
{

  den.aspects.rockhopper = {
    includes = [ forwarded ];
    nixos = {
      imports = [ { options.fwd-target = targetSubmodule; } ];
      fwd-target = {
        foo = [ "zero" ];
        imports = [ oneModule ];
      };
    };
    fwd-origin.foo = [ "two" ];
  };

  perSystem =
    { rockhopper, checkCond, ... }:
    {
      checks.forward = checkCond "foo value was forwarded to os-level" (
        rockhopper.config.fwd-target.foo == [
          "two"
          "one"
          "zero"
        ]
      );
    };

}
