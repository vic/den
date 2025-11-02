{
  inputs,
  lib,
  ...
}:
{
  options.den = lib.mkOption {
    type = lib.types.submodule ({
      # den provides batteries included.
      options.provides = lib.mkOption {
        default = { };
        description = "Batteries Included - re-usable high-level aspects";
        type = lib.types.submodule {
          freeformType = lib.types.attrsOf (inputs.flake-aspects.lib lib).types.providerType;
        };
      };

      imports = [ (lib.mkAliasOptionModule [ "_" ] [ "provides" ]) ];
    });
  };
}
