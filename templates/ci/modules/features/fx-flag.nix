{
  denTest,
  inputs,
  lib,
  ...
}:
{
  flake.tests.fx-flag = {

    # Flag defaults to false.
    test-flag-default-false = denTest (
      { den, ... }:
      {
        expr = den.fxPipeline;
        expected = false;
      }
    );

    # Flag can be set to true.
    test-flag-settable = denTest (
      { den, ... }:
      {
        den.fxPipeline = true;
        expr = den.fxPipeline;
        expected = true;
      }
    );

  };
}
