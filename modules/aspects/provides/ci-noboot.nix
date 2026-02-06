{ config, lib, ... }:
{
  den.default.includes = lib.optionals (config ? _module.args.CI) [
    {
      nixos.fileSystems."/".device = lib.mkDefault "/dev/noroot";
      nixos.boot.loader.grub.enable = lib.mkDefault false;
    }
  ];
}
