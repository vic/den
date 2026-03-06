{ denTest, ... }:
{

  # See den#165, https://github.com/Cybolic/nix-den-bug-double-import-routes/tree/3cccc7c
  flake.tests.deadbugs-cybolic-routes = {

    test-has-no-dups = denTest (
      {
        den,
        lib,
        tuxHm,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.includes = [ den._.bidirectional-provider ];

        den.aspects.igloo.provides.tux = den.lib.parametric {
          includes = [ den.aspects.testing ];
        };

        den.aspects.testing =
          { user, ... }:
          {
            homeManager =
              { pkgs, ... }:
              {
                home.packages = [ pkgs.vim ];
              };
          };

        expr = lib.filter (lib.hasInfix "vim") (map lib.getName tuxHm.home.packages);
        expected = [ "vim" ];
      }
    );
  };

}
