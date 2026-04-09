{ den, ... }:
{
  den.aspects.monitoring = {
    nixos.services.prometheus.enable = true;
    provides.node-exporter.nixos.services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
    provides.nginx-exporter.nixos.services.prometheus.exporters.nginx.enable = true;
    provides.alerting.nixos.services.prometheus.alertmanager = {
      enable = true;
      configuration.route.receiver = "null";
      configuration.receivers = [ { name = "null"; } ];
    };
  };
}
