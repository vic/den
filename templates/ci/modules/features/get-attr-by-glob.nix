{ denTest, ... }:
let
  mockConfig = {
    den = {
      provides = {
        hostname = _: { };
      };

      aspects = {
        cli.provides = {
          bat.enable = true;
          btop.enable = true;
        };

        tui.provides = {
          vim.enable = true;
        };
      };

      ful = {
        gui.provides = {
          vscode.enable = false;
        };
      };
    };
  };
in
{

  flake.tests.get-attr-by-glob = {

    test-in-lib = denTest (
      { den, lib, ... }:
      {
        expr = lib.isFunction den.lib.getAttrByGlob;
        expected = true;
      }
    );

    test-plain-string = denTest (
      { den, ... }:
      {
        expr = den.lib.getAttrByGlob [ "den" "aspects" "cli" ] mockConfig;
        expected = {
          provides = {
            bat.enable = true;
            btop.enable = true;
          };
        };
      }
    );
  };

}
