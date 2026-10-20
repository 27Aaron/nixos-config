{
  config,
  lib,
  ...
}:
let
  cfg = config.core'.logging;
in
{
  options.core'.logging = {
    enable = lib.mkEnableOption "bounded system logs and core dumps";

    journalMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "2G";
      description = ''
        Upper bound for the persistent journal in /var/log/journal.
      '';
    };

    journalRuntimeMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "256M";
      description = ''
        Upper bound for the volatile journal in /run/log/journal. /run is a
        tmpfs, so this is memory, not disk.
      '';
    };

    coredumpMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "1G";
      description = ''
        Upper bound for stored core dumps in /var/lib/systemd/coredump.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # 兩者的預設上限都是所在檔案系統的 10%。這個目錄 bind 掛載自
    # 持久卷,因此「預設」等於允許長到幾十 GB 才開始淘汰,對筆電毫無意義。
    services.journald.settings.Journal = {
      SystemMaxUse = cfg.journalMaxUse;
      RuntimeMaxUse = cfg.journalRuntimeMaxUse;
    };

    # core dump 是從行程記憶體抄出來的,可能含金鑰,不值得跨重啟保留;
    # 上限之外再於開機時清空,只留當次開機的當機現場供除錯。
    systemd.coredump.settings.Coredump.MaxUse = cfg.coredumpMaxUse;

    systemd.tmpfiles.rules = [
      "D! /var/lib/systemd/coredump 0755 root root"
    ];
  };
}
