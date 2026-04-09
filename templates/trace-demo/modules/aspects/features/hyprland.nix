{ den, ... }:
{
  den.aspects.hyprland = {
    nixos.programs.hyprland.enable = true;
    homeManager.wayland.windowManager.hyprland.enable = true;
  };
}
