# Instantiate osConfigurations from hosts
{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}:
let
  hosts = lib.flatten (map builtins.attrValues (builtins.attrValues config.den));

  mkSystem =
    class: if class == "darwin" then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

  osConfiguration = host: {
    name = host.name;
    value = withSystem host.system (
      { inputs', self', ... }:
      (mkSystem host.class) {
        inherit (host) system;
        specialArgs = { inherit inputs' self'; };
        modules = [ self.modules.${host.class}.${host.aspect} ];
      }
    );
  };

  osConfigurations =
    class: builtins.listToAttrs (map osConfiguration (builtins.filter (x: x.class == class) hosts));

  flake.nixosConfigurations = osConfigurations "nixos";
  flake.darwinConfigurations = osConfigurations "darwin";
in
{
  inherit flake;
}
