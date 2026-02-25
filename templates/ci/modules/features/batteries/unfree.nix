{ denTest, ... }:
{
  flake.tests.unfree = {

    test-packages-set-on-nixos = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ (den._.unfree [ "discord" ]) ];
        expr = igloo.nixpkgs.config.allowUnfreePredicate { pname = "discord"; };
        expected = true;
      }
    );

    test-packages-set-on-home-manager = denTest (
      { den, tuxHm, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";
        den.aspects.tux.includes = [ (den._.unfree [ "vscode" ]) ];

        expr = tuxHm.nixpkgs.config.allowUnfreePredicate { pname = "vscode"; };
        expected = true;
      }
    );

    test-user-class-works = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.tux.includes = [ (den._.unfree [ "vscode" ]) ];

        # In order to check that the user class hasn't broken, we force its
        # evaluation through realizing `igloo.users.users.tux`. If it's broken,
        # we'll see an error, so the expected value isn't important here -- it
        # just needs to pass if there isn't an error.
        expr = igloo.users.users.tux.name;
        expected = "tux";
      }
    );

  };
}
