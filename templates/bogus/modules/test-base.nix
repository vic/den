{ den, lib, ... }:
{
  den.default.nixos.system.stateVersion = "25.11";
  den.default.homeManager.home.stateVersion = "25.11";
  den.default.darwin.system.stateVersion = 6;

  den.default.includes = [
    den._.home-manager
    den._.define-user
    den.aspects.no-boot
  ];

  den.aspects.no-boot.nixos = {
    boot.loader.grub.enable = lib.mkForce false;
    fileSystems."/".device = lib.mkForce "/dev/fake";
  };
}
