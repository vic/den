{
  denTest,
  inputs,
  lib,
  ...
}:
{
  flake.tests.fx-flag = {

    # Flag defaults to true.
    test-flag-default-false = denTest (
      { den, ... }:
      {
        expr = den.fxPipeline;
        expected = true;
      }
    );

    # Flag can be set to false.
    test-flag-settable = denTest (
      { den, ... }:
      {
        den.fxPipeline = false;
        expr = den.fxPipeline;
        expected = false;
      }
    );

  };
}
