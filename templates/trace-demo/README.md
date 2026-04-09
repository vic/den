# Trace Demo: Adapter-Based Excludes, Substitutions, and Visualization

Demonstrates den's adapter composition patterns: excludes by name and provider,
aspect substitution, and resolution tracing with Mermaid diagrams.

## Hosts

| Host              | Adapter Pattern                              |
| ----------------- | -------------------------------------------- |
| `laptop`          | Baseline — no adapters, full tree            |
| `desktop-gdm`     | Substitute regreet → gdm                     |
| `web-server`      | Exclude nginx-exporter provider              |
| `mail-relay`      | Exclude monitoring by aspect reference       |
| `devbox`          | Exclude tailscale across two roles           |
| `provider-filter` | Exclude by meta.provider prefix              |
| `angle-brackets`  | Bracket includes + exclude adapter           |
| `multi-desktop`   | Multi-user: alice (hyprland) + bob (gnome)   |

## Legend

| Shape | Meaning |
| ----- | ------- |
| `([...])` | Host root |
| `[/...\]` | Provider sub-aspect |
| `[...]` | Aspect |
| dashed border | Excluded or replaced |

## Usage

```bash
nix run .#write-files     # writes traces/ and this README
nix build .#trace-laptop  # individual trace derivation
```

## Rendered Traces

### angle-brackets

```mermaid
graph TD
  angle_brackets([angle-brackets]):::host

  subgraph nixos[nixos]
  nixos_alice[alice]
  nixos_desktop[desktop]
  nixos_hyprland[hyprland]
  nixos_networking[networking]
  nixos_primary_user[primary-user]
  nixos_regreet[regreet]
  nixos_tailscale[tailscale]:::excluded
  nixos_alice --> nixos_hyprland
  nixos_alice --> nixos_primary_user
  angle_brackets --> nixos_alice
  angle_brackets --> nixos_desktop
  angle_brackets --> nixos_networking
  angle_brackets -.-x nixos_tailscale
  nixos_desktop --> nixos_regreet
  end
  subgraph homeManager[homeManager]
  homeManager_alice[alice]
  homeManager_dev_tools[dev-tools]
  homeManager_hyprland[hyprland]
  homeManager_shell[shell]
  homeManager_tailscale[tailscale]:::excluded
  homeManager_alice --> homeManager_dev_tools
  homeManager_alice --> homeManager_hyprland
  homeManager_alice --> homeManager_shell
  angle_brackets --> homeManager_alice
  angle_brackets -.-x homeManager_tailscale
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

### desktop-gdm

```mermaid
graph TD
  desktop_gdm([desktop-gdm]):::host

  subgraph nixos[nixos]
  nixos_alice[alice]
  nixos_desktop[desktop]
  nixos_gdm[gdm]
  nixos_hyprland[hyprland]
  nixos_networking[networking]
  nixos_primary_user[primary-user]
  nixos_regreet[regreet]:::replaced
  nixos_tailscale[tailscale]
  nixos_workstation[workstation]
  nixos_alice --> nixos_hyprland
  nixos_alice --> nixos_primary_user
  nixos_desktop --> nixos_gdm
  nixos_desktop -.->|replaced| nixos_regreet
  desktop_gdm --> nixos_alice
  desktop_gdm --> nixos_workstation
  nixos_workstation --> nixos_desktop
  nixos_workstation --> nixos_networking
  nixos_workstation --> nixos_tailscale
  end
  subgraph homeManager[homeManager]
  homeManager_alice[alice]
  homeManager_desktop[desktop]
  homeManager_dev_tools[dev-tools]
  homeManager_hyprland[hyprland]
  homeManager_shell[shell]
  homeManager_workstation[workstation]
  homeManager_alice --> homeManager_dev_tools
  homeManager_alice --> homeManager_hyprland
  homeManager_alice --> homeManager_shell
  desktop_gdm --> homeManager_alice
  desktop_gdm --> homeManager_workstation
  homeManager_workstation --> homeManager_desktop
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

### devbox

```mermaid
graph TD
  devbox([devbox]):::host

  subgraph nixos[nixos]
  nixos_alerting[/monitoring/alerting\]
  nixos_alice[alice]
  nixos_desktop[desktop]
  nixos_hyprland[hyprland]
  nixos_monitoring[monitoring]
  nixos_networking[networking]
  nixos_nginx_exporter[/monitoring/nginx-exporter\]
  nixos_node_exporter[/monitoring/node-exporter\]
  nixos_primary_user[primary-user]
  nixos_regreet[regreet]
  nixos_server[server]
  nixos_tailscale[tailscale]:::excluded
  nixos_workstation[workstation]
  nixos_alice --> nixos_hyprland
  nixos_alice --> nixos_primary_user
  nixos_desktop --> nixos_regreet
  devbox --> nixos_alice
  devbox --> nixos_server
  devbox --> nixos_workstation
  nixos_server --> nixos_alerting
  nixos_server --> nixos_monitoring
  nixos_server --> nixos_networking
  nixos_server --> nixos_nginx_exporter
  nixos_server --> nixos_node_exporter
  nixos_server -.-x nixos_tailscale
  nixos_workstation --> nixos_desktop
  nixos_workstation --> nixos_networking
  nixos_workstation -.-x nixos_tailscale
  end
  subgraph homeManager[homeManager]
  homeManager_alice[alice]
  homeManager_dev_tools[dev-tools]
  homeManager_hyprland[hyprland]
  homeManager_server[server]
  homeManager_shell[shell]
  homeManager_workstation[workstation]
  homeManager_alice --> homeManager_dev_tools
  homeManager_alice --> homeManager_hyprland
  homeManager_alice --> homeManager_shell
  devbox --> homeManager_alice
  devbox --> homeManager_server
  devbox --> homeManager_workstation
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

### laptop

```mermaid
graph TD
  laptop([laptop]):::host

  subgraph nixos[nixos]
  nixos_alice[alice]
  nixos_desktop[desktop]
  nixos_hyprland[hyprland]
  nixos_networking[networking]
  nixos_primary_user[primary-user]
  nixos_regreet[regreet]
  nixos_tailscale[tailscale]
  nixos_workstation[workstation]
  nixos_alice --> nixos_hyprland
  nixos_alice --> nixos_primary_user
  nixos_desktop --> nixos_regreet
  laptop --> nixos_alice
  laptop --> nixos_workstation
  nixos_workstation --> nixos_desktop
  nixos_workstation --> nixos_networking
  nixos_workstation --> nixos_tailscale
  end
  subgraph homeManager[homeManager]
  homeManager_alice[alice]
  homeManager_dev_tools[dev-tools]
  homeManager_hyprland[hyprland]
  homeManager_shell[shell]
  homeManager_alice --> homeManager_dev_tools
  homeManager_alice --> homeManager_hyprland
  homeManager_alice --> homeManager_shell
  laptop --> homeManager_alice
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

### mail-relay

```mermaid
graph TD
  mail_relay([mail-relay]):::host

  subgraph nixos[nixos]
  nixos_alerting[/monitoring/alerting\]:::excluded
  nixos_deploy[deploy]
  nixos_mail[mail]
  nixos_monitoring[monitoring]:::excluded
  nixos_networking[networking]
  nixos_nginx_exporter[/monitoring/nginx-exporter\]:::excluded
  nixos_node_exporter[/monitoring/node-exporter\]:::excluded
  nixos_relay[relay]
  nixos_server[server]
  nixos_tailscale[tailscale]
  mail_relay --> nixos_deploy
  mail_relay --> nixos_relay
  nixos_relay --> nixos_mail
  nixos_relay --> nixos_server
  nixos_server -.-x nixos_alerting
  nixos_server -.-x nixos_monitoring
  nixos_server --> nixos_networking
  nixos_server -.-x nixos_nginx_exporter
  nixos_server -.-x nixos_node_exporter
  nixos_server --> nixos_tailscale
  end
  subgraph homeManager[homeManager]
  homeManager_deploy[deploy]
  homeManager_relay[relay]
  homeManager_server[server]
  mail_relay --> homeManager_deploy
  mail_relay --> homeManager_relay
  homeManager_relay --> homeManager_server
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

### multi-desktop

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

### provider-filter

```mermaid
graph TD
  provider_filter([provider-filter]):::host

  subgraph nixos[nixos]
  nixos_alerting[/monitoring/alerting\]:::excluded
  nixos_deploy[deploy]
  nixos_monitoring[monitoring]
  nixos_networking[networking]
  nixos_nginx_exporter[/monitoring/nginx-exporter\]:::excluded
  nixos_node_exporter[/monitoring/node-exporter\]:::excluded
  nixos_server[server]
  nixos_tailscale[tailscale]
  provider_filter --> nixos_deploy
  provider_filter --> nixos_server
  nixos_server -.-x nixos_alerting
  nixos_server --> nixos_monitoring
  nixos_server --> nixos_networking
  nixos_server -.-x nixos_nginx_exporter
  nixos_server -.-x nixos_node_exporter
  nixos_server --> nixos_tailscale
  end
  subgraph homeManager[homeManager]
  homeManager_deploy[deploy]
  homeManager_server[server]
  provider_filter --> homeManager_deploy
  provider_filter --> homeManager_server
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

### web-server

```mermaid
graph TD
  web_server([web-server]):::host

  subgraph nixos[nixos]
  nixos_alerting[/monitoring/alerting\]
  nixos_deploy[deploy]
  nixos_monitoring[monitoring]
  nixos_networking[networking]
  nixos_nginx_exporter[/monitoring/nginx-exporter\]:::excluded
  nixos_node_exporter[/monitoring/node-exporter\]
  nixos_server[server]
  nixos_tailscale[tailscale]
  nixos_server --> nixos_alerting
  nixos_server --> nixos_monitoring
  nixos_server --> nixos_networking
  nixos_server -.-x nixos_nginx_exporter
  nixos_server --> nixos_node_exporter
  nixos_server --> nixos_tailscale
  web_server --> nixos_deploy
  web_server --> nixos_server
  end
  subgraph homeManager[homeManager]
  homeManager_deploy[deploy]
  homeManager_server[server]
  web_server --> homeManager_deploy
  web_server --> homeManager_server
  end

  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold
  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5
  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5
style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px
style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px
```

