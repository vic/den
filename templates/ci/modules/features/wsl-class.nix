{ denTest, ... }:
let
  mockWslModule =
    { lib, ... }:
    {
      options.wsl.defaultUser = lib.mkOption { type = lib.types.str; };
    };
in
{
  flake.tests.wsl-class = {

    test-wsl-forwards = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          wsl.enable = true;
          wsl.module = mockWslModule;
          users.tux = { };
        };

        den.aspects.tux.includes = [ den.provides.primary-user ];

        expr = igloo.wsl.defaultUser;
        expected = "tux";
      }
    );

  };
}
