{ denTest, ... }:
{
  flake.tests.user-packages = {

    test-user-packages-set-on-nixos = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.tux.includes = [ (den._.user-packages [ "discord" ]) ];

        expr = igloo.config.users.users.tux.packages;
        expected = [ "discord" ];
      }
    );

    test-user-packages-set-on-home-manager = denTest (
      { den, tuxHm, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";
        den.aspects.tux.includes = [ (den._.user-packages [ "discord" ]) ];

        expr = tuxHm.config.home.packages;
        expected = [ "discord" ];
      }
    );

  };
}
