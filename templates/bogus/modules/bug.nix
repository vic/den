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

        imports = [
          # one.nix
          {
            den.aspects.foo =
              { host }:
              {
                nixos = lib.optionalAttrs (host.hostName == "igloo") {
                  environment.sessionVariables.FOO = host.hostName;
                };
              };
          }
          # two.nix
          {
            den.aspects.foo =
              { host }:
              {
                nixos = lib.optionalAttrs (host.hostName == "igloo") {
                  networking.hostName = "cold";
                };
              };
          }
        ];

        den.aspects.igloo.includes = [ den.aspects.foo ];

        expr = { 
          hostName = igloo.networking.hostName;
          FOO = igloo.environment.sessionVariables.FOO;
        };
        expected.hostName = "cold";
        expected.FOO = "igloo";
      }
    );

  };
}
