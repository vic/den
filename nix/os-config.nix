# Instantiate osConfigurations from hosts
{
  inputs,
  lib,
  config,
  ...
}:
let
  hosts = lib.attrValues config.den.hosts;

  mkSystem =
    class: if class == "darwin" then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

  osConfiguration = host: {
    name = host.name;
    value = (mkSystem host.class) {
      system = host.system;
      modules = [ inputs.self.modules.${host.class}.${host.aspect} ];
    };
  };

  osConfigurations =
    class: lib.listToAttrs (lib.map osConfiguration (lib.filter (x: x.class == class) hosts));

  flake.nixosConfigurations = osConfigurations "nixos";
  flake.darwinConfigurations = osConfigurations "darwin";
in
{
  inherit flake;
}
