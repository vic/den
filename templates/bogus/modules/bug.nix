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

        imports = let

          # includes the subaspect named "sub" (which comes from the "foo" main
          # aspect) INSIDE the "foo" main aspect itself, given that an "enable" option from the
          # schema is satisfied
          a = {
            den.aspects.foo = { host, ... }: {
              includes = lib.optionals (host.foo._.sub.enable == true) [
                den.aspects.foo._.sub
              ];
            };
          };

          # declares that "enable" option in the schema
          b = {
            den.schema.host.options.foo._.sub.enable = lib.mkEnableOption "asdf";
          };

          # enables that "enable" in the schema
          c = {
            den.hosts.x86_64-linux.igloo.foo._.sub.enable = true;
          };

          # does a fancy thing in the sub aspect that I think was overlooked
          # in https://github.com/vic/den/pull/410
          d = {
            den.aspects.foo._.sub = { host, ... }: {
              nixos = lib.optionalAttrs (host.hostName != "whatever") {
                networking.networkmanager.enable = true;
              };
            };
          };

        in [
          a b c d
        ];

        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [
          den.aspects.foo
        ];

        expr = igloo.networking.networkmanager.enable;
        expected = true;
      }
    );

  };
}
