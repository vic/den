{ denTest, ... }:
{
  flake.tests.perUser-perHost = {

    test-included-in-default-pipeline = denTest (
      {
        den,
        igloo,
        lib,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.aspects.igloo.nixos.options.funny = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
        };

        den.aspects.igloo.includes = [
          (den.lib.perHost { nixos.funny = [ "atHost perHost static" ]; })
          (den.lib.perHost (
            { host }:
            {
              nixos.funny = [ "atHost perHost ${host.name} fun" ];
            }
          ))
          (den.lib.perUser { nixos.funny = [ "atHost IGNORED perUser static" ]; })
          (den.lib.perUser (
            { user, host }:
            {
              nixos.funny = [ "atHost IGNORED perUser ${user.name}@${host.name} fun" ];
            }
          ))
        ];

        den.aspects.tux.includes = [
          (den.lib.perHost { nixos.funny = [ "atUser IGNORED perHost static" ]; })
          (den.lib.perHost (
            { host }:
            {
              nixos.funny = [ "atUser IGNORED perHost ${host.name} fun" ];
            }
          ))
          (den.lib.perUser { nixos.funny = [ "atUser perUser static" ]; })
          (den.lib.perUser (
            { user, host }:
            {
              nixos.funny = [ "atUser perUser ${user.name}@${host.name} fun" ];
            }
          ))
        ];

        expr = igloo.funny;
        expected = [
          "atUser perUser tux@igloo fun"
          "atUser perUser static"
          "atHost perHost igloo fun"
          "atHost perHost static"
        ];
      }
    );

    test-included-in-bidirectional-pipeline = denTest (
      {
        den,
        igloo,
        lib,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.ctx.user.includes = [ den._.bidirectional ];

        den.aspects.igloo.nixos.options.funny = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
        };

        den.aspects.igloo.includes = [
          (den.lib.perHost { nixos.funny = [ "atHost perHost static" ]; })
          (den.lib.perHost (
            { host }:
            {
              nixos.funny = [ "atHost perHost ${host.name} fun" ];
            }
          ))
          (den.lib.perUser { nixos.funny = [ "atHost perUser static" ]; })
          (den.lib.perUser (
            { user, host }:
            {
              nixos.funny = [ "atHost perUser ${user.name}@${host.name} fun" ];
            }
          ))
        ];

        den.aspects.tux.includes = [
          (den.lib.perHost { nixos.funny = [ "atUser ignored perHost static" ]; })
          (den.lib.perHost (
            { host }:
            {
              nixos.funny = [ "atUser ignored perHost ${host.name} fun" ];
            }
          ))
          (den.lib.perUser { nixos.funny = [ "atUser perUser static" ]; })
          (den.lib.perUser (
            { user, host }:
            {
              nixos.funny = [ "atUser perUser ${user.name}@${host.name} fun" ];
            }
          ))
        ];

        expr = igloo.funny;
        expected = [
          "atHost perUser pingu@igloo fun"
          "atHost perUser static" # pingu
          "atHost perUser tux@igloo fun"
          "atHost perUser static" # tux
          "atUser perUser tux@igloo fun"
          "atUser perUser static"
          "atHost perHost igloo fun"
          "atHost perHost static"
        ];
      }
    );

  };
}
