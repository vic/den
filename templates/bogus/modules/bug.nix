{ denTest, lib, ... }:
{
  flake.tests.bogus = {
    test-something = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        imports =
          let

            b = {
              den.aspects.role = { host, ... }: {
                includes = [
                  den.aspects.role._.sub
                ];
              };
            };

            c = {
              den.aspects.role._.sub.nixos.networking.networkmanager.enable = true;
            };
            # Change c to the below, and it works.
            # c = {
            #   den.aspects.role._.sub = { ... }: {
            #     nixos.networking.networkmanager.enable = true;
            #   };
            # };

            e = {
              den.aspects.igloo.includes = [ den.aspects.role ];
            };
          in
          [ b c e ];

        expr = igloo.networking.networkmanager.enable;
        expected = true;
      }
    );
  };
}
