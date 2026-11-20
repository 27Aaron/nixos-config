{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.node-exporter;
in
{
  options.services'.node-exporter = {
    enable = lib.mkEnableOption "Prometheus node_exporter host metrics";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9100;
      description = ''
        Port on which node_exporter listens. Metrics are meant to be pulled
        over the tailnet, so the port is only opened on the tailscale0
        interface and stays unreachable from other networks.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services'.tailscale.enable;
        message = "services'.node-exporter only opens its port on tailscale0; enable services'.tailscale.";
      }
    ];

    services.prometheus.exporters.node = {
      enable = true;
      inherit (cfg) port;
      openFirewall = false;
      enabledCollectors = [
        "processes"
        "systemd"
      ];
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];
  };
}
