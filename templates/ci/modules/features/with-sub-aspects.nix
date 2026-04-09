{ denTest, ... }:
{
  flake.tests.with-sub-aspects = {
    test-is-in-lib = denTest (
      { den, lib, ... }:
      {
        expr = lib.isFunction den.lib.withSubAspects;
        expected = true;
      }
    );
  };
}
