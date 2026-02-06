# it is possible for top-level aspects directly under
# den.aspects to take a context argument.
{ den, lib, ... }:
let
  # A module to test that toplevel had context.
  topLevel = name: {
    config.tops = name;
    options.tops = lib.mkOption { type = lib.types.str; };
  };
in
{

  den.aspects.toplevel-user =
    { user, ... }:
    {
      nixos.imports = [ (topLevel user.name) ];
    };

  den.aspects.toplevel-host =
    { host, ... }:
    {
      homeManager.imports = [ (topLevel host.name) ];
    };

  den.aspects.rockhopper.includes = [
    den.aspects.toplevel-host
  ];

  den.aspects.alice.includes = [
    den.aspects.toplevel-user
  ];

  perSystem =
    {
      checkCond,
      alice-at-rockhopper,
      rockhopper,
      ...
    }:
    {
      checks.alice-toplevel-user = checkCond "alice toplevel param aspect" (
        rockhopper.config.tops == "alice"
      );

      checks.alice-toplevel-host = checkCond "alice toplevel param aspect" (
        alice-at-rockhopper.tops == "rockhopper"
      );
    };

}
