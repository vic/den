{ denTest, lib, ... }:
{
  flake.tests.bogus = {
    test-something = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        imports =
          let
            a = {
              den.schema.host.options.role._.sub.enable = lib.mkEnableOption "sub";
            };

            b = {
              den.aspects.role = { host, ... }: {
                includes = lib.optionals host.role._.sub.enable [
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

            d = {
              den.hosts.x86_64-linux.igloo.role._.sub.enable = true;
            };

            e = {
              den.aspects.igloo.includes = [ den.aspects.role ];
            };
          in
          [ a b c d e ];

        expr = igloo.networking.networkmanager.enable;
        expected = true;
      }
    );
  };
}
