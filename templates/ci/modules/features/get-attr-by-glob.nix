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
        expected = mockConfig.den.aspects.cli;
      }
    );

    test-den-provided = denTest (
      { den, lib, ... }:
      {
        expr = lib.isFunction (den.lib.getAttrByGlob [ "den" "provides" "hostname" ] mockConfig);
        expected = true;
      }
    );

    test-den-ful = denTest (
      { den, ... }:
      {
        expr = den.lib.getAttrByGlob [ "den" "ful" "gui" "provides" "vscode" ] mockConfig;
        expected = mockConfig.den.ful.gui.provides.vscode;
      }
    );
  };

}
