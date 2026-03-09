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

        den.aspects.printing =
          { user, ... }:
          {
            nixos =
              { pkgs, ... }:
              {
                users.users.${user.userName}.extraGroups = [
                  "lp"
                  "scanner"
                ];
              };
          };

        den.aspects.igloo.includes = [ den.aspects.printing ];

        expr = igloo.users.users.tux.extraGroups;
        expected = [
          "lp"
          "scanner"
        ];
      }
    );
  };
}
