{ denTest, ... }:
{
  flake.tests.standalone-homes = {

    test-home-configuration-created = denTest (
      { den, config, ... }:
      {
        den.homes.x86_64-linux.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";

        expr = config.flake.homeConfigurations ? tux;
        expected = true;
      }
    );

    test-home-aspect-config-applied = denTest (
      { den, config, ... }:
      {
        den.homes.x86_64-linux.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";
        den.default.includes = [ den._.define-user ];
        den.aspects.tux.homeManager.programs.fish.enable = true;

        expr = config.flake.homeConfigurations.tux.config.programs.fish.enable;
        expected = true;
      }
    );

    test-home-custom-username = denTest (
      { den, config, ... }:
      {
        den.homes.x86_64-linux.cam = {
          userName = "cameron";
        };
        den.default.homeManager.home.stateVersion = "25.11";
        den.default.includes = [ den._.define-user ];

        expr = config.flake.homeConfigurations.cam.config.home.username;
        expected = "cameron";
      }
    );

    test-ctx-home-applies-aspect = denTest (
      { den, config, ... }:
      {
        den.homes.x86_64-linux.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";
        den.default.includes = [ den._.define-user ];
        den.ctx.home.homeManager.programs.vim.enable = true;

        expr = config.flake.homeConfigurations.tux.config.programs.vim.enable;
        expected = true;
      }
    );

  };
}
