{ inputs, lib, ... }:
{
  den.hosts.x86_64-linux.igloo.users.tux = { };
  den.hosts.aarch64-darwin.apple.users.tim = { };

  # Use aspects to create a **minimal** bug reproduction
  den.aspects.igloo.nixos =
    { pkgs, ... }:
    {
      users.users.tux.packages = [ pkgs.hello ];
    };

  # rename "it works", evidently it has bugs
  flake.tests."test it works" =
    let
      tux = inputs.self.nixosConfigurations.igloo.config.users.users.tux;

      expr.len = lib.length tux.packages;
      expr.names = map lib.getName tux.packages;

      expected.len = 1;
      expected.names = [ "hello" ];
    in
    {
      inherit expr expected;
    };
}
