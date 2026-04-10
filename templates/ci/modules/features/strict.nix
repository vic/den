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
          msg = "The option `den.hosts.x86_64-linux.igloo.arbitrary' does not exist";
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
          msg = "The option `den.hosts.x86_64-linux.igloo.users.tux.arbitrary' does not exist";
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
          msg = "The option `den.aspects.igloo.arbitrary' does not exist";
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
          msg = "The option `flake.arbitray' does not exist";
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
        flake.arbitray = "value";

        expr = config.flake.arbitray;
        expectedError = {
          type = "ThrownError";
          msg = "The option `flake.arbitray' does not exist";
        };
      }
    );
  };
}
