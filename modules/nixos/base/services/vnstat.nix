{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.vnstat;
in
{
  options.services'.vnstat = {
    enable = lib.mkEnableOption "vnStat network traffic monitor";
  };

  config = lib.mkIf cfg.enable {
    services.vnstat.enable = true;

    preservation'.os.directories = [
      {
        directory = "/var/lib/vnstat";
        user = "vnstatd";
        group = "vnstatd";
      }
    ];
  };
}
