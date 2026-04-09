# Test helpers for evaluating Den on isolation
#
# Exports _module.args.denTest
{
  inputs,
  lib,
  config,
  ...
}:
let
  # isolated test, prevent polution between tests.
  denTest = module: {
    inherit ((evalDen module).config) expr expected;
  };

  # emulate fake-parts only for self and nixpkgs.
  withSystem =
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      inputs'.nixpkgs.packages = pkgs;
      inputs'.nixpkgs.legacyPackages = pkgs;
      self'.packages = pkgs;
      self'.legacyPackages = pkgs;
    in
    cb: cb { inherit inputs' self'; };

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
        config.denTest
      ];
    };

  testModule = {
    imports = [ inputs.den.flakeModule ];
    options.expr = lib.mkOption { };
    options.expected = lib.mkOption { };
    config = {
      den.schema.user.classes = lib.mkDefault [ "homeManager" ];
      den.default.nixos.system.stateVersion = lib.mkDefault "25.11";
      den.default.homeManager.home.stateVersion = lib.mkDefault "25.11";
    };
  };

  helpersModule =
    { config, den, ... }:
    let

      iceberg = config.flake.nixosConfigurations.iceberg.config;
      apple = config.flake.darwinConfigurations.apple.config;
      igloo = config.flake.nixosConfigurations.igloo.config;
      tuxHm = igloo.home-manager.users.tux;
      pinguHm = igloo.home-manager.users.pingu;

      sort = lib.sort (a: b: a < b);
      show = items: builtins.trace (lib.concatStringsSep " / " (lib.flatten [ items ]));

      trace = with den.lib.aspects; {
        __functor = _: resolve.withAdapter adapters.trace;
        over = outer: resolve.withAdapter (outer adapters.trace);
      };

      funnyNames =
        aspect:
        let
          resolve = config.den.lib.aspects.resolve;
          mod = resolve "funny" aspect;
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
          apple
          igloo
          iceberg
          tuxHm
          pinguHm
          trace
          ;
      };
    };
in
{
  config._module.args = { inherit denTest; };
  options.denTest = lib.mkOption {
    default = { };
    type = lib.types.deferredModule;
  };
}
