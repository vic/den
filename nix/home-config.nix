# Instantiate homeConfigurations from standalone homes
{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}:
let
  homes = lib.flatten (map builtins.attrValues (builtins.attrValues config.den.homes));

  homeConfiguration = home: {
    inherit (home) name;
    value = withSystem home.system (
      { pkgs, ... }:
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ self.modules.${home.class}.${home.aspect} ];
      }
    );
  };

  homeConfigurations =
    class: builtins.listToAttrs (map homeConfiguration (builtins.filter (x: x.class == class) homes));

  flake.homeConfigurations = homeConfigurations "homeManager";
in
{
  inherit flake;
}
