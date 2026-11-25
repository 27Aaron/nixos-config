{ config, lib, ... }:
{
  # NixOS 在每臺主機都啟用 logrotate,狀態檔不保留的話,每次開機後都會重新輪替。
  # 持久化整個目錄:logrotate 以寫暫存檔再 rename() 更新狀態檔,單檔 bind
  # 掛載會導致 EBUSY。
  preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
    "/var/lib/logrotate"
  ];

  services.logrotate.extraArgs = [
    "--state"
    "/var/lib/logrotate/status"
  ];
}
