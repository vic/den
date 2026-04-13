{ denTest, ... }:
{
  flake.tests.system-packages = {

    test-system-packages-set-on-nixos = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ (den._.system-packages [ "discord" ]) ];

        expr = igloo.config.environment.systemPackages;
        expected = [ "discord" ];
      }
    );

  };
}
