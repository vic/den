{ denTest, ... }:
{
  flake.tests.os-class = {

    test-forwards-to-nixos-and-darwin = denTest (
      {
        den,
        lib,
        igloo,
        apple,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.aarch64-darwin.apple.users.tux = { };

        # user contributes to both NixOS and MacOS
        den.aspects.tux = {
          os.networking.hostName = "from-os-class";
        };

        expr = {
          nixos = igloo.networking.hostName;
          macos = apple.networking.hostName;
        };
        expected = {
          nixos = "from-os-class";
          macos = "from-os-class";
        };
      }
    );

  };
}
