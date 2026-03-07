{ denTest, ... }:
{
  flake.tests.hostname = {

    test-sets-hostname = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.includes = [ den._.hostname ];

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );

    test-sets-custom-hostname = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          hostName = "sahara";
          users.tux = { };
        };

        den.default.includes = [ den._.hostname ];

        expr = igloo.networking.hostName;
        expected = "sahara";
      }
    );

  };
}
