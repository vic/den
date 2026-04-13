{ denTest, lib, ... }:
{
  flake.tests.strict-mode = {
    test-relaxed-mode = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux = { };

          arbitrary = "value";
        };

        expr = den.hosts.x86_64-linux.igloo.arbitrary;
        expected = "value";
      }
    );

    test-strict-mode-host = denTest (
      { den, ... }:
      {
        den.schema.host = den.lib.strict;

        den.hosts.x86_64-linux.igloo = {
          users.tux = { };
          arbitrary = "value";
        };

        expr = den.hosts.x86_64-linux.igloo.arbitrary;
        expectedError = {
          type = "ThrownError";
          msg = "Attempted to set the option \"arbitrary\" in \"den.hosts.x86_64-linux.igloo\"";
        };
      }
    );

    test-strict-mode-user = denTest (
      { den, ... }:
      {
        den.schema.user = den.lib.strict;

        den.hosts.x86_64-linux.igloo.users.tux.arbitrary = "value";

        expr = den.hosts.x86_64-linux.igloo.users.tux.arbitrary;
        expectedError = {
          type = "ThrownError";
          msg = "Attempted to set the option \"arbitrary\" in \"den.hosts.x86_64-linux.igloo.users.tux\"";
        };
      }
    );

    test-strict-mode-aspect = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.schema.aspect = den.lib.strict;
        den.aspects.igloo.arbitrary = { };

        expr = den.aspects.igloo.arbitrary;
        expectedError = {
          type = "ThrownError";
          msg = "Attempted to set the option \"arbitrary\" in \"den.aspects.igloo\"";
        };
      }
    );

    test-strict-mode-flake = denTest (
      { den, config, ... }:
      {
        den.schema.flake = den.lib.strict;
        flake.arbitray = "value";

        expr = config.flake.arbitray;
        expectedError = {
          type = "ThrownError";
          msg = "Attempted to set the option \"arbitray\" in \"flake\"";
        };
      }
    );

    test-strict-mode-flake-customisable = denTest (
      { den, config, ... }:
      {
        den.schema.flake.imports = [
          den.lib.strict
          {
            options.arbitrary = lib.mkOption {
              type = lib.types.str;
            };
          }
        ];
        flake.arbitrary = "value";

        expr = config.flake.arbitrary;
        expected = "value";
      }
    );

    flakeModule = {
      test-aspect-nixos = denTest (
        { inputs, igloo, ... }:
        {
          imports = [
            inputs.den.flakeModules.strict
            inputs.den.flakeOutputs.all
          ];

          den.hosts.x86_64-linux.igloo = { };
          den.aspects.igloo.nixos.networking.hostName = "igloo";

          expr = igloo.networking.hostName;
          expected = "igloo";
        }
      );

      test-aspect-darwin = denTest (
        { inputs, apple, ... }:
        {
          imports = [
            inputs.den.flakeModules.strict
            inputs.den.flakeOutputs.all
          ];

          den.hosts.aarch64-darwin.apple = { };
          den.aspects.apple.darwin.networking.hostName = "apple";

          expr = apple.networking.hostName;
          expected = "apple";
        }
      );

      test-aspect-os = denTest (
        {
          inputs,
          igloo,
          apple,
          ...
        }:
        {
          imports = [
            inputs.den.flakeModules.strict
            inputs.den.flakeOutputs.all
          ];

          den.hosts.x86_64-linux.igloo = { };
          den.aspects.igloo.os.networking.hostName = "igloo";

          den.hosts.aarch64-darwin.apple = { };
          den.aspects.apple.os.networking.hostName = "apple";

          expr = {
            apple = apple.networking.hostName;
            igloo = igloo.networking.hostName;
          };
          expected = {
            apple = "apple";
            igloo = "igloo";
          };
        }
      );

      test-aspect-homeManager = denTest (
        { inputs, tuxHm, ... }:
        {
          imports = [
            inputs.den.flakeModules.strict
            inputs.den.flakeOutputs.all
          ];

          den.schema.user.classes = [ "homeManager" ];

          den.hosts.x86_64-linux.igloo.users.tux = { };
          den.aspects.tux.homeManager.programs.vim.enable = true;

          expr = tuxHm.programs.vim.enable;
          expected = true;
        }
      );

      test-aspect-user = denTest (
        { inputs, tux, ... }:
        {
          imports = [
            inputs.den.flakeModules.strict
            inputs.den.flakeOutputs.all
          ];

          den.hosts.x86_64-linux.igloo.users.tux = { };

          den.aspects.tux.user.extraGroups = [ "test" ];

          expr = tux.extraGroups;
          expected = [ "test" ];
        }
      );

      test-aspect-wsl = denTest (
        { inputs, igloo, ... }:
        {
          imports = [
            inputs.den.flakeModules.strict
            inputs.den.flakeOutputs.all
          ];

          den.hosts.x86_64-linux.igloo = {
            wsl.enable = true;
            users.tux = { };
          };

          den.aspects.igloo.wsl.defaultUser = "igloo";

          expr =
            if inputs ? nixos-wsl then
              igloo.wsl.defaultUser
            else
              lib.warn "nixos-wsl not found in inputs, skipping test `strict-mode.flakeModule.test-aspect-wsl" "igloo";
          expected = "igloo";
        }
      );

      test-host = denTest (
        { inputs, den, ... }:
        {
          imports = [ inputs.den.flakeModules.strict ];

          den.hosts.x86_64-linux.igloo.arbitrary = "value";

          expr = den.hosts.x86_64-linux.igloo.arbitrary;
          expectedError = {
            type = "ThrownError";
            msg = "Attempted to set the option \"arbitrary\" in \"den.hosts.x86_64-linux.igloo\"";
          };
        }
      );

      test-user = denTest (
        { inputs, den, ... }:
        {
          imports = [ inputs.den.flakeModules.strict ];

          den.hosts.x86_64-linux.igloo.users.tux.arbitrary = "value";

          expr = den.hosts.x86_64-linux.igloo.users.tux.arbitrary;
          expectedError = {
            type = "ThrownError";
            msg = "Attempted to set the option \"arbitrary\" in \"den.hosts.x86_64-linux.igloo.users.tux\"";
          };
        }
      );

      test-aspect = denTest (
        { inputs, den, ... }:
        {
          imports = [ inputs.den.flakeModules.strict ];

          den.aspects.test.arbitrary = "value";

          expr = den.aspects.test.arbitrary;
          expectedError = {
            type = "ThrownError";
            msg = "Attempted to set the option \"arbitrary\" in \"den.aspects.test\"";
          };
        }
      );

      test-flake = denTest (
        { inputs, config, ... }:
        {
          imports = [ inputs.den.flakeModules.strict ];

          flake.arbitrary = "value";

          expr = config.flake.arbitrary;
          expectedError = {
            type = "ThrownError";
            msg = "Attempted to set the option \"arbitrary\" in \"flake\"";
          };
        }
      );

      test-namespace = denTest (
        {
          inputs,
          test,
          lib,
          ...
        }:
        {
          imports = [
            inputs.den.flakeModules.strict
            (inputs.den.namespace "test" true)
          ];

          test.lib.flatMap = f: arr: lib.concatMap f arr;

          expr = test.lib.flatMap (x: [ x ]) [
            1
            2
            3
          ];
          expectedError = {
            type = "ThrownError";
            msg = "Attempted to set the option \"flatMap\" in \"den.ful.test.lib\"";
          };
        }
      );

      test-namespace-fix = denTest (
        {
          inputs,
          test,
          lib,
          ...
        }:
        {
          imports = [
            inputs.den.flakeModules.strict
            (inputs.den.namespace "test" true)
          ];

          den.schema.namespace.options.lib = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.unspecified;
          };

          test.lib.flatMap = f: arr: lib.concatMap f arr;

          expr =
            test.lib.flatMap
              (x: [
                x
                x
              ])
              [
                1
                2
                3
              ];
          expected = [
            1
            1
            2
            2
            3
            3
          ];
        }
      );
    };
  };
}
