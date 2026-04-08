{ denTest, ... }:
{

  flake.tests.get-attr-by-glob = {

    test-non-glob-lookup = denTest (
      { den, __findFile, ... }:
      {
        _module.args.__findFile = den.lib.__findFile;
        expr = true;
        expected = false;
      }
    );

  };

}
