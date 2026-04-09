# Aspect Trace: provider-filter

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
