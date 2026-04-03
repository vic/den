{ denTest, ... }:
{
  flake.tests.aspect-meta = {
    test-can-be-self-inspected = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.base ];

        den.aspects.base =
          { host, ... }:
          { config, ... }:
          {
            nixos.networking.hostName = config.meta.name;
            meta.name = "${host.name} McLoving";
          };


        expr = igloo.networking.hostName;
        expected = "igloo McLoving";
      }
    );
  };
}
