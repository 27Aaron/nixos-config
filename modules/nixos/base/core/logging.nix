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

  config = {
    # 上游預設上限為檔案系統的 10%;/var/log 位於持久卷,等同數十 GB。
    services.journald.settings.Journal = {
      SystemMaxUse = cfg.journalMaxUse;
      RuntimeMaxUse = cfg.journalRuntimeMaxUse;
    };

    # core dump 可能含金鑰:除了限制大小,開機時也一併清空,只保留本次開機的紀錄。
    systemd.coredump.settings.Coredump.MaxUse = cfg.coredumpMaxUse;

    systemd.tmpfiles.rules = [
      "D! /var/lib/systemd/coredump 0755 root root"
    ];
  };
}
