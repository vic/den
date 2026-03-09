# copy this file and rename `new` and `something`
# adapt the code to assert something via `expr` and `expected`.
# denTest is defined at test-support/eval-den.nix and provides args:
#   - igloo = nixosConfigurations.igloo.config
#   - tuxHm = igloo.home-manager.users.tux
{ denTest, ... }:
{
  flake.tests.new = {
    test-something = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.base =
          { host, ... }:
          {
            nixos.networking.hostName = host.hostName;
          };

        den.aspects.igloo.includes = [ den.aspects.base ];

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );
  };
}
