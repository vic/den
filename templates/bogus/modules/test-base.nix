# DO NOT EDIT.
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
        denModule
      ];
    };

  denModule = {
    imports = [ inputs.den.flakeModule ];
    den.default.homeManager.home.stateVersion = "26.05";
    den.default.nixos = {
      system.stateVersion = "26.05";
      boot.loader.grub.enable = lib.mkForce false;
      fileSystems."/".device = lib.mkForce "/dev/fake";
    };
  };

  testModule = {
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

  imports = [
    inputs.den.flakeModule
    inputs.nix-unit.modules.flake.default
  ];

  systems = lib.systems.flakeExposed;
  flake.packages.x86_64-linux.hello = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;

  perSystem.nix-unit = {
    allowNetwork = lib.mkDefault true;
    inputs = lib.mkDefault inputs;
  };
}
