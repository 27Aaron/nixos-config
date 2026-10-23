{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.logrotate;
in
{
  options.services'.logrotate = {
    enable = lib.mkEnableOption "log rotation with persistent state";
  };

  config = lib.mkIf cfg.enable {
    # 保留輪替進度。持久化整個目錄:logrotate 以寫暫存檔再 rename() 更新
    # 狀態檔,單檔 bind 掛載會導致 EBUSY。
    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      "/var/lib/logrotate"
    ];

    services.logrotate.extraArgs = [
      "--state"
      "/var/lib/logrotate/status"
    ];
  };
}
