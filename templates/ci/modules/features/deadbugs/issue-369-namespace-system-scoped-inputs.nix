{ denTest, ... }:
{
  flake.tests.deadbugs-issue-369 = {

    test-everything-includes = denTest (
      {
        den,
        lib,
        igloo,
        inputs,
        gloom,
        __findFile,
        tuxHm,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "gloom" false) ];
        _module.args.__findFile = den.lib.__findFile;

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";

        den.default.includes = [ den._.inputs' den._.define-user ];
        den.aspects.tux.includes = [ gloom.everywhere ];
        gloom.everywhere.includes = [ <gloom/apps/helix> ];

        gloom.apps.provides.helix.includes = [ den._.inputs' ];
        gloom.apps.provides.helix.homeManager =
          { inputs', ... }@args:
          builtins.trace (lib.attrNames args)
          {
            packages = [ inputs'.nixpkgs.legacyPackages.hello ];
          };

        expr = builtins.elem "hello" (map lib.getName tuxHm.packages);
        expected = true;
      }
    );

  };
}
