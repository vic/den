{ den, lib, ... }:
let
  inherit (den.lib)
    parametric
    take
    ;

  description = ''
    This is a private aspect always included in den.default.

    It adds a module option that gathers all packages defined
    in den._.unfree usages and declares a 
    nixpkgs.config.allowUnfreePredicate for each class.

  '';

  unfreeComposableModule.options.unfree = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  nixosAspect =
    { config, ... }:
    {
      nixpkgs.config.allowUnfreePredicate = (pkg: builtins.elem (lib.getName pkg) config.unfree.packages);
    };

  homeManagerAspect =
    { config, osConfig, ... }:
    {
      nixpkgs = lib.mkIf (!osConfig.home-manager.useGlobalPkgs) {
        config.allowUnfreePredicate = (pkg: builtins.elem (lib.getName pkg) config.unfree.packages);
      };
    };

  aspect = parametric.exactly {
    inherit description;
    includes = [
      (
        { OS, host }:
        let
          unused = take.unused OS;
        in
        {
          ${host.class}.imports = unused [
            unfreeComposableModule
            nixosAspect
          ];
        }
      )
      (
        {
          OS,
          HM,
          user,
          host,
        }:
        let
          unused = take.unused [
            OS
            HM
            host
          ];
        in
        {
          ${user.class}.imports = unused [
            unfreeComposableModule
            homeManagerAspect
          ];
        }
      )
      (
        { HM, home }:
        let
          unused = take.unused HM;
        in
        {
          ${home.class}.imports = unused [
            unfreeComposableModule
            nixosAspect
          ];
        }
      )
    ];
  };
in
{
  den.default.includes = [ aspect ];
}
