{ den, ... }:
{
  den.aspects.regreet.nixos.programs.regreet.enable = true;
  den.aspects.gdm.nixos.services.xserver.displayManager.gdm.enable = true;
  den.aspects.sddm.nixos.services.displayManager.sddm.enable = true;
}
