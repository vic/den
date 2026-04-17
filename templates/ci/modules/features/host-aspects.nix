# Battery: host-aspects — projects host homeManager configs to opted-in users.
{ denTest, ... }:
{
  flake.tests.host-aspects = {

    # Host aspect with homeManager key projects to user who includes den._.host-aspects.
    test-host-hm-projects-to-user = denTest (
      {
        den,
        lib,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.homeManager.programs.vim.enable = true;
        den.aspects.tux.includes = [ den._.host-aspects ];

        expr = tuxHm.programs.vim.enable;
        expected = true;
      }
    );

    # Host aspect with only nixos key does NOT leak into user's homeManager.
    test-nixos-only-does-not-leak = denTest (
      {
        den,
        lib,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.nixos.networking.hostName = "igloo";
        den.aspects.tux.includes = [ den._.host-aspects ];

        expr = tuxHm.programs.vim.enable;
        expected = false;
      }
    );

    # Verify no circular eval when accessing both host and user configs.
    test-no-circular-eval = denTest (
      {
        den,
        lib,
        igloo,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.homeManager.programs.vim.enable = true;
        den.aspects.igloo.nixos.networking.hostName = "igloo";
        den.aspects.tux.includes = [ den._.host-aspects ];

        expr = {
          hostName = igloo.networking.hostName;
          vim = tuxHm.programs.vim.enable;
        };
        expected = {
          hostName = "igloo";
          vim = true;
        };
      }
    );

    # Multiple host sub-aspects with homeManager keys all project.
    test-multiple-host-aspects = denTest (
      {
        den,
        lib,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [
          { homeManager.programs.vim.enable = true; }
          { homeManager.programs.git.enable = true; }
        ];

        den.aspects.tux.includes = [ den._.host-aspects ];

        expr = {
          vim = tuxHm.programs.vim.enable;
          git = tuxHm.programs.git.enable;
        };
        expected = {
          vim = true;
          git = true;
        };
      }
    );

    # Host nixos modules are NOT duplicated when user includes host-aspects.
    # Uses a listOf option to detect double-application.
    test-no-nixos-duplication = denTest (
      {
        den,
        lib,
        igloo,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.nixos.imports = [
          {
            options.tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        ];

        den.aspects.igloo = {
          nixos.tags = [ "host" ];
          homeManager.programs.vim.enable = true;
        };

        den.aspects.tux.includes = [ den._.host-aspects ];

        expr = {
          tags = igloo.tags;
          vim = tuxHm.programs.vim.enable;
        };
        expected = {
          # "host" should appear exactly once — not duplicated
          tags = [ "host" ];
          vim = true;
        };
      }
    );

    # User who does NOT include den._.host-aspects does not receive host homeManager.
    test-opt-in-only = denTest (
      {
        den,
        lib,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.homeManager.programs.vim.enable = true;
        # tux does NOT include den._.host-aspects

        expr = tuxHm.programs.vim.enable;
        expected = false;
      }
    );

  };
}
