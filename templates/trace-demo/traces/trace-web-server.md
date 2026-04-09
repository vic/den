# Aspect Trace: web-server

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
