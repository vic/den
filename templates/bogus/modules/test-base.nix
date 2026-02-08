# DO-NOT-EDIT unless necessary. Keep your reproduction repo minimal.
{
  den,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.den.flakeModule
    inputs.nix-unit.modules.flake.default
  ];

  systems = lib.attrNames den.hosts;

  den.default.nixos.system.stateVersion = "26.05";
  den.default.homeManager.home.stateVersion = "26.05";

  den.default.includes = [
    den.provides.home-manager
    den.provides.define-user
    den.aspects.no-boot
  ];

  den.aspects.no-boot.nixos = {
    boot.loader.grub.enable = lib.mkForce false;
    fileSystems."/".device = lib.mkForce "/dev/fake";
  };

  perSystem.nix-unit = {
    allowNetwork = lib.mkDefault true;
    inputs = lib.mkDefault inputs;
  };
}
