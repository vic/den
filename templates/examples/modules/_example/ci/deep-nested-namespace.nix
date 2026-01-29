{
  inputs,
  lib,
  deep,
  ...
}:
let
  deepModule.nixos.options.deepVals = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };
  depthA = {
    denful.deep.a._.b._.c._.d._.e = {
      description = "5 levels deep from inputA";
      nixos.deepVals = [ "inputA-5-levels" ];
      provides.f.nixos.deepVals = [ "inputA-6-levels" ];
    };
  };
  depthB = {
    denful.deep.a._.b._.c._.d._.e = {
      nixos.deepVals = [ "inputB-5-levels" ];
      provides.f.nixos.deepVals = [ "inputB-6-levels" ];
    };
  };
in
{
  imports = [
    (inputs.den.namespace "deep" [
      true
      depthA
      depthB
    ])
  ];

  deep.a._.b._.c._.d._.e = {
    nixos.deepVals = [ "local-5-levels" ];
    provides.f.nixos.deepVals = [ "local-6-levels" ];
  };

  den.aspects.rockhopper.includes = [
    deepModule
    deep.a._.b._.c._.d._.e
    deep.a._.b._.c._.d._.e._.f
  ];

  perSystem =
    { checkCond, rockhopper, ... }:
    let
      vals = lib.sort (a: b: a < b) rockhopper.config.deepVals;
    in
    {
      checks.deep-nest-5-levels = checkCond "5 levels deep merged correctly" (
        builtins.elem "inputA-5-levels" vals
        && builtins.elem "inputB-5-levels" vals
        && builtins.elem "local-5-levels" vals
      );

      checks.deep-nest-6-levels = checkCond "6 levels deep merged correctly" (
        builtins.elem "inputA-6-levels" vals
        && builtins.elem "inputB-6-levels" vals
        && builtins.elem "local-6-levels" vals
      );

      checks.deep-nest-all-merged = checkCond "all values merged" (
        vals == [
          "inputA-5-levels"
          "inputA-6-levels"
          "inputB-5-levels"
          "inputB-6-levels"
          "local-5-levels"
          "local-6-levels"
        ]
      );

      checks.deep-nest-flake-output = checkCond "deep namespace as flake output" (
        inputs.self.denful.deep.a._.b._.c._.d._.e._.f == deep.a._.b._.c._.d._.e._.f
      );
    };
}
