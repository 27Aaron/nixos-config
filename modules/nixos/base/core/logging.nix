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
      description = "Persistent journal size cap.";
    };

    journalRuntimeMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "256M";
      description = "Volatile journal size cap, counted against RAM because /run is tmpfs.";
    };

    coredumpMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "1G";
      description = "Core dump size cap.";
    };
  };

  config = lib.mkIf cfg.enable {
    # 上游預設上限是檔案系統的 10%,而這裡 bind 掛載自持久卷,等於允許數十 GB。
    services.journald.settings.Journal = {
      SystemMaxUse = cfg.journalMaxUse;
      RuntimeMaxUse = cfg.journalRuntimeMaxUse;
    };

    # core dump 可能含金鑰,除上限外再由下方 tmpfiles 的 D! 於開機時清空,
    # 只留當次開機的當機現場。
    systemd.coredump.settings.Coredump.MaxUse = cfg.coredumpMaxUse;

    systemd.tmpfiles.rules = [
      "D! /var/lib/systemd/coredump 0755 root root"
    ];
  };
}
