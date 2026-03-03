{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  # isolated test, prevent polution between tests.
  denTest = module: {
    inherit ((evalDen module).config) expr expected;
  };

  evalDen =
    module:
    lib.evalModules {
      specialArgs = {
        inherit inputs;
        inherit withSystem;
      };
      modules = [
        module
        testModule
        helpersModule
      ];
    };

  testModule = {
    imports = [ inputs.den.flakeModule ];
    options.flake.nixosConfigurations = lib.mkOption { };
    options.flake.homeConfigurations = lib.mkOption { };
    options.flake.packages = lib.mkOption { };
    options.expr = lib.mkOption { };
    options.expected = lib.mkOption { };
  };

  helpersModule =
    { config, ... }:
    let

      iceberg = config.flake.nixosConfigurations.iceberg.config;
      igloo = config.flake.nixosConfigurations.igloo.config;
      tuxHm = igloo.home-manager.users.tux;
      pinguHm = igloo.home-manager.users.pingu;

      sort = lib.sort (a: b: a < b);
      show = items: builtins.trace (lib.concatStringsSep " / " (lib.flatten [ items ]));

      funnyNames =
        aspect:
        let
          mod = aspect.resolve { class = "funny"; };
          namesMod = {
            options.names = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
          res = lib.evalModules {
            modules = [
              mod
              namesMod
            ];
          };
        in
        sort res.config.names;

    in
    {
      _module.args = {
        inherit
          show
          funnyNames
          igloo
          iceberg
          tuxHm
          pinguHm
          ;
      };
    };

in
{
  _module.args = { inherit denTest evalDen; };

  flake.packages.x86_64-linux.hello = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
}
