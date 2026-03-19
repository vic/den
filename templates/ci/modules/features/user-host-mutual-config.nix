{ denTest, ... }:
{
  flake.tests.user-host-mutual-config = {

    test-host-owned-unidirectional = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        # no mutuality enabled, this is ignored
        den.aspects.igloo.homeManager.programs.direnv.enable = true;

        expr = [
          tuxHm.programs.direnv.enable
          pinguHm.programs.direnv.enable
        ];
        expected = [
          false
          false
        ];
      }
    );

    test-host-owned-mutual = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.ctx.user.includes = [ den._.mutual-provider ];
        den.aspects.igloo._.to-users.homeManager.programs.direnv.enable = true;

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

    test-host-mutual-static-includes-configures-all-users = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.ctx.user.includes = [ den._.mutual-provider ];

        den.aspects.igloo._.to-users.includes = [
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

    test-host-parametric-unidirectional = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {

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
          false
          false
        ];
      }
    );

    test-host-parametric-mutual = denTest (
      {
        den,
        tuxHm,
        pinguHm,
        ...
      }:
      {

        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.ctx.user.includes = [ den._.mutual-provider ];

        den.aspects.igloo._.to-users.includes = [
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

    test-user-static-unidirectional-configures-all-hosts = denTest (
      {
        den,
        igloo,
        iceberg,
        ...
      }:
      {

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
