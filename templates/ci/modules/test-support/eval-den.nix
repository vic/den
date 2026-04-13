{
  inputs,
  denTest,
  lib,
  ...
}:
{
  imports = [
    inputs.den.flakeModules.denTest
    inputs.den.flakeOutputs.tests
  ];

  options.flake = {
    denTest = lib.mkOption { };
    den = lib.mkOption { };
  };

  config.flake = {
    inherit denTest;
    den =
      (denTest (
        { den, ... }:
        {
          expr = den;
          expected = den;
        }
      )).expr;
  };
}
