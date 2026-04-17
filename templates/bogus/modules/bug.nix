{ denTest, ... }:
{
  flake.tests.bogus = {

    test-something = denTest (
      {
        den,
        lib,
        # igloo, # igloo = nixosConfigurations.igloo.config
        apple,
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        den.hosts.aarch64-darwin.apple = {
          users.tux =
            { config, ... }:
            {
              # Added custom submodule per instructions at
              # https://den.oeiuwq.com/v0.16.0/guides/configure-aspects/#aspect-custom-submodule

              imports = [
                {
                  options.categories = lib.mkOption {
                    type = with lib.types; attrsOf str;
                    default = {
                      programs = "programs";
                    };
                  };
                }
              ];
            };
        };

        expr = apple.users.users.tux.categories.programs;
        expected = "programs";
      }
    );

  };
}
