{ denTest, ... }:
{
  flake.tests.user-host-bidirectional-config = {

    test-host-owned-configures-all-users = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.aspects.igloo.homeManager.programs.direnv.enable = true;

        expr = [
          tuxHm.programs.direnv.enable
          pinguHm.programs.direnv.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

    test-host-static-configures-all-users = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.aspects.igloo.includes = [
          {
            homeManager.programs.direnv.enable = true;
          }
        ];

        expr = [
          tuxHm.programs.direnv.enable
          pinguHm.programs.direnv.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

    test-host-parametric-configures-all-users = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.aspects.igloo.includes = [
          (
            { host, user }:
            {
              homeManager.programs.direnv.enable = true;
            }
          )
        ];

        expr = [
          tuxHm.programs.direnv.enable
          pinguHm.programs.direnv.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

    test-user-owned-configures-all-hosts = denTest (
      {
        den,
        igloo,
        iceberg,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.tux = { };

        den.aspects.tux.nixos.programs.fish.enable = true;

        expr = [
          igloo.programs.fish.enable
          iceberg.programs.fish.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

    test-user-static-configures-all-hosts = denTest (
      {
        den,
        igloo,
        iceberg,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.tux = { };

        den.aspects.tux.includes = [
          {
            nixos.programs.fish.enable = true;
          }
        ];

        expr = [
          igloo.programs.fish.enable
          iceberg.programs.fish.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

    test-user-function-configures-all-hosts = denTest (
      {
        den,
        igloo,
        iceberg,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.tux = { };

        den.aspects.tux.includes = [
          (
            { host, user }:
            {
              nixos.programs.fish.enable = true;
            }
          )
        ];

        expr = [
          igloo.programs.fish.enable
          iceberg.programs.fish.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

  };
}
