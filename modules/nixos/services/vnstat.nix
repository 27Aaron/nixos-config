{ config, lib, ... }:
let
  cfg = config.services'.vnstat;
in
{
  options.services'.vnstat = {
    enable = lib.mkEnableOption "vnstat network traffic monitor";
  };

  config = lib.mkIf cfg.enable {
    services.vnstat.enable = true;

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/var/lib/vnstat";
        user = "vnstatd";
        group = "vnstatd";
      }
    ];
  };
}
