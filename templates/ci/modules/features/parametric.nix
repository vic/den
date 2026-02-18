{ denTest, ... }:
{
  flake.tests.parametric = {

    test-parametric-forwards-context = denTest (
      { den, igloo, ... }:
      let
        foo = den.lib.parametric {
          includes = [
            (
              { host, ... }:
              {
                nixos.users.users.tux.description = host.name;
              }
            )
          ];
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.users.users.tux.description;
        expected = "igloo";
      }
    );

    test-parametric-owned-config = denTest (
      { den, igloo, ... }:
      let
        foo = den.lib.parametric {
          nixos.networking.hostName = "from-parametric-owned";
          includes = [ ];
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.networking.hostName;
        expected = "from-parametric-owned";
      }
    );

    test-parametric-fixedTo = denTest (
      { den, igloo, ... }:
      let
        foo =
          { host, ... }:
          den.lib.parametric.fixedTo { planet = "Earth"; } {
            includes = [
              (
                { planet, ... }:
                {
                  nixos.users.users.tux.description = planet;
                }
              )
            ];
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.users.users.tux.description;
        expected = "Earth";
      }
    );

    test-parametric-expands = denTest (
      { den, igloo, ... }:
      let
        foo = den.lib.parametric.expands { planet = "Earth"; } {
          includes = [
            (
              { host, planet, ... }:
              {
                nixos.users.users.tux.description = "${host.name}/${planet}";
              }
            )
          ];
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.users.users.tux.description;
        expected = "igloo/Earth";
      }
    );

    test-never-matches-aspect-skipped = denTest (
      { den, igloo, ... }:
      let
        never-matches =
          { never-exists, ... }:
          {
            nixos.networking.hostName = "NEVER";
          };
        sets-hostname =
          { host, ... }:
          {
            nixos.networking.hostName = host.name;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = den.lib.parametric {
          includes = [
            sets-hostname
            never-matches
          ];
        };

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );

  };
}
