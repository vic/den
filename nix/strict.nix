{ den, lib, ... }:
let
  moduleOption = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };

  defaultClasses.options = {
    nixos = moduleOption;
    darwin = moduleOption;
  };
in
{
  den.schema.host = den.lib.strict;
  den.schema.user = den.lib.strict;
  den.schema.home = den.lib.strict;
  den.schema.flake = den.lib.strict;

  den.schema.aspect.imports = [
    den.lib.strict
    defaultClasses
  ];
}
