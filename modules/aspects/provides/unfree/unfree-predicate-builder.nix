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

  unfreeModule =
    { config, ... }@args:
    let
      # nixpkgs.config must not be set when useGlobalPkgs is true.
      globalPkgs = args.osConfig.home-manager.useGlobalPkgs or false;
    in
    {
      options.unfree.packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      config.nixpkgs = lib.mkIf (!globalPkgs) {
        config.allowUnfreePredicate = (pkg: builtins.elem (lib.getName pkg) config.unfree.packages);
      };
    };

  osAspect = { OS, host }: take.unused OS { ${host.class}.imports = [ unfreeModule ]; };

  userAspect =
    {
      HM,
      user,
      host,
    }:
    take.unused [ HM host ] { ${user.class}.imports = [ unfreeModule ]; };

  homeAspect = { HM, home }: take.unused HM { ${home.class}.imports = [ unfreeModule ]; };

  aspect = parametric.exactly {
    inherit description;
    includes = [
      osAspect
      userAspect
      homeAspect
    ];
  };
in
{
  den.default.includes = [ aspect ];
}
