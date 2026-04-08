{ denTest, ... }:
let
  cfg = {
    den.provides.hostname = _: { };
    den.aspects.cli.provides.ed.enable = true;
    den.aspects.tui.provides.vim.enable = true;
    den.aspects.gui.provides.vscode.enable = false;
    den.ful.gui.provides.emacs.enable = true;
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
        expr = den.lib.getAttrByGlob [ "den" "aspects" "cli" ] cfg;
        expected = cfg.den.aspects.cli;
      }
    );

    test-den-provided = denTest (
      { den, ... }:
      {
        expr = builtins.isFunction (den.lib.getAttrByGlob [ "den" "provides" "hostname" ] cfg);
        expected = true;
      }
    );

    test-den-ful = denTest (
      { den, ... }:
      {
        expr = den.lib.getAttrByGlob [ "den" "ful" "gui" "provides" "emacs" ] cfg;
        expected = cfg.den.ful.gui.provides.emacs;
      }
    );

    test-with-braces = denTest (
      { den, ... }:
      {
        expr = den.lib.getAttrByGlob [ "den" "aspects" "{cli}" ] cfg;
        expected = {
          provides.ed.enable = true;
        };
      }
    );

    test-with-braces-and-comma = denTest (
      { den, ... }:
      {
        expr = den.lib.getAttrByGlob [ "den" "aspects" "{cl,{g,t}u}i" ] cfg;
        expected = {
          provides.ed.enable = true;
          provides.vim.enable = true;
          provides.vscode.enable = false;
        };
      }
    );

    test-with-braces-and-star = denTest (
      { den, ... }:
      {
        expr = den.lib.getAttrByGlob [ "den" "aspects" "{*}" ] cfg;
        expected = {
          provides.ed.enable = true;
          provides.vim.enable = true;
          provides.vscode.enable = false;
        };
      }
    );
  };

}
