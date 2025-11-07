{ lib, config, ... }:
{
  options.den = lib.mkOption {
    type = lib.types.submodule {
      imports = [
        (lib.mkAliasOptionModule [ "_" ] [ "provides" ])
      ];
      options.provides = lib.mkOption {
        default = { };
        description = "Batteries Included - re-usable high-level aspects";
        type = lib.types.submodule {
          freeformType = lib.types.attrsOf config.den.lib.aspects.types.providerType;
        };
      };
    };
  };
}
