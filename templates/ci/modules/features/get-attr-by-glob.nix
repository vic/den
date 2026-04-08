{ denTest, ... }:
{

  flake.tests.get-attr-by-glob = {

    test-in-lib = denTest (
      { den, lib, ... }:
      {
        expr = lib.isFunction den.lib.getAttrByGlob;
        expected = true;
      }
    );

  };

}
