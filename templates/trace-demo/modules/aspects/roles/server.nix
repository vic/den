{ den, ... }:
{
  den.aspects.server.includes = with den.aspects; [
    networking
    monitoring
    monitoring._.node-exporter
    monitoring._.nginx-exporter
    monitoring._.alerting
    tailscale
  ];
}
