{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.tailscale;
in
{
  options.services'.tailscale = {
    enable = lib.mkEnableOption "Tailscale client";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open the WireGuard tunnel port (UDP 41641) so nodes can establish
        direct connections instead of relaying through DERP.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      inherit (cfg) openFirewall;
    };

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/var/lib/tailscale";
        mode = "0700";
      }
    ];
  };
}
