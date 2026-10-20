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
    # logrotate 預設把進度記在 /var/lib/logrotate.status。根目錄是 tmpfs,
    # 這個檔案每次開機都消失,於是每次輪替都像「從未轉過」。
    #
    # 這裡持久化整個目錄而非單一檔案:logrotate 以「寫暫存檔再 rename()」
    # 的方式原子替換 state 檔,單檔 bind mount 會讓 rename() 撞上 EBUSY。
    preservation'.os.directories = [
      "/var/lib/logrotate"
    ];

    services.logrotate.extraArgs = [
      "--state"
      "/var/lib/logrotate/status"
    ];
  };
}
