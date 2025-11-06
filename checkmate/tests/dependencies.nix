{ lib, inputs, ... }:
let
  den-lib = inputs.target.lib lib inputs;
in
{
  flake.tests."test default dependency" = {
    expr = lib.length [
      lib
      inputs
      den-lib
    ];
    expected = false;
  };
}
