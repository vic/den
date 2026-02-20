{ denTest, ... }:
{
  flake.tests.host-options = {

    test-custom-hostname-attr = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          hostName = "polar-station";
          users.tux = { };
        };

        expr = den.hosts.x86_64-linux.igloo.hostName;
        expected = "polar-station";
      }
    );

    test-hostname-used-in-networking = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";
        den.default.includes = [
          (
            { host, ... }:
            {
              ${host.class}.networking.hostName = host.hostName;
            }
          )
        ];

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );

    test-custom-aspect-name = denTest (
      { den, config, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          aspect = "my-custom-aspect";
          users.tux = { };
        };
        den.default.homeManager.home.stateVersion = "25.11";
        den.aspects.my-custom-aspect.nixos.networking.hostName = "from-custom";

        expr = config.flake.nixosConfigurations.igloo.config.networking.hostName;
        expected = "from-custom";
      }
    );

    test-default-aspect-is-name = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        expr = den.hosts.x86_64-linux.igloo.aspect;
        expected = "igloo";
      }
    );

    test-user-custom-username = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = {
          userName = "penguin";
        };
        den.default.homeManager.home.stateVersion = "25.11";
        den.aspects.igloo.includes = [ den._.define-user ];

        expr = igloo.users.users.penguin.isNormalUser;
        expected = true;
      }
    );

  };
}
