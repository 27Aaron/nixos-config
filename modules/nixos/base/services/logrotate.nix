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
    # 進度檔在 tmpfs 上每次開機都消失,輪替會像「從未轉過」。
    # 持久化整個目錄而非單一檔案:logrotate 以「寫暫存檔再 rename()」原子替換
    # state 檔,單檔 bind mount 會讓 rename() 撞上 EBUSY。
    preservation'.os.directories = [
      "/var/lib/logrotate"
    ];

    services.logrotate.extraArgs = [
      "--state"
      "/var/lib/logrotate/status"
    ];
  };
}
