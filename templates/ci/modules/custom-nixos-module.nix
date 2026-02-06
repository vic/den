{ lib, ... }:
let
  # A custom `nixos` class module that defines an option `names`.
  # Used to test that we are not duplicating values from owned configs.
  nixosNames = names: { options.${names} = lib.mkOption { type = lib.types.listOf lib.types.str; }; };
in
{
  den.default.nixos.imports = [ (nixosNames "people") ];
  den.default.includes = [
    (
      { user, ... }:
      {
        nixos.people = [ user.name ];
      }
    )
  ];

  den.aspects.rockhopper.includes = [
    # Example: importing a third-party nixos module.
    { nixos.imports = [ (nixosNames "names") ]; }
  ];

  den.aspects.rockhopper.nixos.names = [ "tux" ];

  perSystem =
    { checkCond, rockhopper, ... }:
    {
      checks.rockhopper-default-people = checkCond "set from den.default for each user" (
        rockhopper.config.people == [ "alice" ]
      );
      checks.rockhopper-names-single-entry = checkCond "custom nixos array option set once" (
        rockhopper.config.names == [ "tux" ]
      );
    };
}
