# Aspect Trace: multi-desktop

```mermaid
graph TD
  multi_desktop([multi-desktop]):::host

  subgraph nixos[nixos]
  nixos_alice[alice]
  nixos_bob[bob]
  nixos_desktop[desktop]
  nixos_gnome[gnome]
  nixos_hyprland[hyprland]
  nixos_networking[networking]
  nixos_primary_user[primary-user]
  nixos_regreet[regreet]
  nixos_tailscale[tailscale]
  nixos_workstation[workstation]
  nixos_alice --> nixos_hyprland
  nixos_alice --> nixos_primary_user
  nixos_bob --> nixos_gnome
  nixos_bob --> nixos_primary_user
  nixos_desktop --> nixos_regreet
  multi_desktop --> nixos_alice
  multi_desktop --> nixos_bob
  multi_desktop --> nixos_workstation
  nixos_workstation --> nixos_desktop
  nixos_workstation --> nixos_networking
  nixos_workstation --> nixos_tailscale
  end
  subgraph homeManager[homeManager]
  homeManager_alice[alice]
  homeManager_bob[bob]
  homeManager_dev_tools[dev-tools]
  homeManager_gnome[gnome]
  homeManager_hyprland[hyprland]
  homeManager_shell[shell]
  homeManager_alice --> homeManager_dev_tools
  homeManager_alice --> homeManager_hyprland
  homeManager_alice --> homeManager_shell
  homeManager_bob --> homeManager_dev_tools
  homeManager_bob --> homeManager_gnome
  multi_desktop --> homeManager_alice
  multi_desktop --> homeManager_bob
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```
