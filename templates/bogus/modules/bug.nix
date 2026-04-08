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

        den.aspects.igloo.includes = [ den.aspects.foo ];

        imports = 
        let
          one = {
            den.aspects.foo = { host, ... }: {
              nixos.environment.sessionVariables.FOO = host.name;
            };
          };

          two = {
            den.aspects.foo.nixos = { pkgs, ... }: {
              environment.systemPackages = [ pkgs.hello ];
            };
          };
        in
        [ one two ];

        expr = {
          hello = lib.elem "hello" (map lib.getName igloo.environment.systemPackages);
          FOO = igloo.environment.sessionVariables.FOO;
        };
        expected.FOO = "igloo";
        expected.hello = true;
      }
    );

  };
}
