{ denTest, ... }:
{
  flake.tests.bogus = {

    test-something = denTest (
      {
        den,
        lib,
        igloo,
        tuxHm,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.ctx.hm-host.includes = [ (den._.unfree [ "discord" ]) ];

        expr =
          let
            discord-host = igloo.nixpkgs.config.allowUnfreePredicate { pname = "discord"; };
            discord-user = tuxHm.nixpkgs.config.allowUnfreePredicate { pname = "discord"; };
          in
          {
            inherit discord-host discord-user;
          };

        expected = {
          discord-host = true;
          discord-user = false;
        };
      }
    );

  };
}
