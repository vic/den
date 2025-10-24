# Instantiate osConfigurations from hosts
{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  hosts = lib.flatten (map builtins.attrValues (builtins.attrValues config.den.hosts));

  mkSystem =
    class: if class == "darwin" then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

  osConfiguration = host: {
    inherit (host) name;
    value = (mkSystem host.class) {
      inherit (host) system;
      modules = [ self.modules.${host.class}.${host.aspect} ];
    };
  };

  osConfigurations =
    class: builtins.listToAttrs (map osConfiguration (builtins.filter (x: x.class == class) hosts));

  flake.nixosConfigurations = osConfigurations "nixos";
  flake.darwinConfigurations = osConfigurations "darwin";
in
{
  inherit flake;
}
