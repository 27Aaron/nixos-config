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

    # 流量資料庫,擁有者是 vnstatd 服務帳號。
    preservation'.os.directories = [
      {
        directory = "/var/lib/vnstat";
        user = "vnstatd";
        group = "vnstatd";
      }
    ];
  };
}
