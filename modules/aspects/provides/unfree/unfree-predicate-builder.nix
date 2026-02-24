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

  osAspect = take.exactly (
    { host }:
    {
      ${host.class}.imports = [ unfreeModule ];
    }
  );
  userAspect = take.exactly (
    { host, user }: lib.mkMerge (map (c: { ${c}.imports = [ unfreeModule ]; }) user.classes)
  );
  homeAspect = take.exactly (
    { home }:
    {
      ${home.class}.imports = [ unfreeModule ];
    }
  );

  aspect = parametric {
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
