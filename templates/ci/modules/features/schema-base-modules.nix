# Copy this file to start new tests
{ denTest, ... }:
{
  flake.tests.schema-base-modules = {

    test-host-base = denTest (
      { den, lib, ... }:
      {
        den.schema.host =
          { host, ... }:
          {
            options.vpn-alias = lib.mkOption { default = host.name; };
          };

        den.hosts.x86_64-linux.igloo.users.tux = { };

        expr = den.hosts.x86_64-linux.igloo.vpn-alias;
        expected = "igloo";
      }
    );

    test-user-base = denTest (
      { den, lib, ... }:
      {
        den.schema.user =
          { user, host, ... }:
          {
            options.main-group = lib.mkOption { default = user.name; };
            options.description = lib.mkOption { default = "${user.name}@${host.name}"; };
          };

        den.hosts.x86_64-linux.igloo.users.tux = { };

        expr = [
          den.hosts.x86_64-linux.igloo.users.tux.main-group
          den.hosts.x86_64-linux.igloo.users.tux.description
        ];
        expected = [
          "tux"
          "tux@igloo"
        ];
      }
    );

    test-home-base = denTest (
      { den, lib, ... }:
      {
        den.schema.home =
          { home, ... }:
          {
            options.main-group = lib.mkOption { default = home.name; };
          };

        den.homes.x86_64-linux.tux = { };

        expr = den.homes.x86_64-linux.tux.main-group;
        expected = "tux";
      }
    );

    test-conf-base = denTest (
      { den, lib, ... }:
      {
        den.schema.conf =
          { ... }:
          {
            options.foo = lib.mkOption { default = "foo"; };
          };

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.homes.x86_64-linux.tux = { };

        expr = [
          den.hosts.x86_64-linux.igloo.foo
          den.hosts.x86_64-linux.igloo.users.tux.foo
          den.homes.x86_64-linux.tux.foo
        ];
        expected = [
          "foo"
          "foo"
          "foo"
        ];
      }
    );

  };
}
