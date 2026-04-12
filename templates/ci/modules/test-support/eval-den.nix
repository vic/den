{ inputs, denTest, ... }:
{
  imports = [
    inputs.den.flakeModules.denTest
    inputs.den.flakeOutputs.flake
  ];
  flake = {
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
