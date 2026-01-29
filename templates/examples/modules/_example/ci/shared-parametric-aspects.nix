{
  inputs,
  lib,
  shared,
  ...
}:
let
  dataModule.nixos.options.data = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };
  mkInputFlake = name: {
    denful.shared.gaming._.retro._.sega = {
      nixos.data = [ "${name}-sega-static" ];
    };
  };
  inputFoo = mkInputFlake "foo";
  inputBar = mkInputFlake "bar";
in
{
  imports = [
    (inputs.den.namespace "shared" [
      true
      inputFoo
      inputBar
    ])
  ];

  shared.gaming._.retro._.sega.nixos.data = [ "local-sega-static" ];

  den.aspects.rockhopper.includes = [
    dataModule
    shared.gaming._.retro._.sega
  ];

  perSystem =
    { checkCond, rockhopper, ... }:
    let
      vals = lib.sort (a: b: a < b) rockhopper.config.data;
    in
    {
      checks.shared-parametric-all-merged = checkCond "all parametric merged" (
        vals == [
          "bar-sega-static"
          "foo-sega-static"
          "local-sega-static"
        ]
      );

      checks.shared-flake-output-matches = checkCond "flake output matches" (
        shared.gaming._.retro._.sega == inputs.self.denful.shared.gaming._.retro._.sega
      );
    };
}
