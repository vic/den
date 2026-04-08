{ denTest, ... }:
{
  flake.tests.bogus = {

    test-something = denTest (
      {
        den,
        lib,
        igloo, # igloo = nixosConfigurations.igloo.config
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        # replace <system> if you are reporting a bug in MacOS
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.foo = { host }: {
          nixos = lib.optionalAttrs (host.name == "igloo") {
            networking.hostName = "cold";
          };
        };


        expr = igloo.networking.hostName;
        expected = "cold";
      }
    );

  };
}
