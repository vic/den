{ den, ... }:
{
  # Multi-user workstation — alice (hyprland) and bob (gnome) on the same host.
  # Shows how different users include different desktop environments,
  # and how the trace renders per-user aspect trees.
  den.aspects.multi-desktop.includes = with den.aspects; [ workstation ];
}
