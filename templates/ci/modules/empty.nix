# Copy this file to start new tests
{ denTest, ... }:
{
  flake.tests.empty = {
    test-no-aspects = denTest (
      { den, ... }:
      {
        expr = den.aspects;
        expected = { };
      }
    );
  };
}
