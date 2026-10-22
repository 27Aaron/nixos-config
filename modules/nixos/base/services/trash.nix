{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.services'.trash;
  home = config.users.users.${vars.username}.home;
in
{
  options.services'.trash = {
    enable = lib.mkEnableOption "periodic purge of old trash items";

    retentionDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Delete trash items older than this many days.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.trash-cli ];

    # 家目錄的回收桶在 tmpfs 上,重開機即清空;各持久化目錄中的 .Trash-$uid
    # 則會一直累積,檔案總管也不會一併顯示,因此定期清理。
    systemd.services.trash-empty = {
      description = "Purge trash items older than ${toString cfg.retentionDays} days";

      script = ''
        ${pkgs.trash-cli}/bin/trash-empty ${toString cfg.retentionDays} -f
      '';

      # .Trash-$uid 位於 preservation 的 bind 掛載內,而這些掛載不排在
      # local-fs.target 之後,所以兩者都要等。
      after = [
        "local-fs.target"
        "preservation.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        User = vars.username;
        Environment = [
          "HOME=${home}"
          "XDG_DATA_HOME=${home}/.local/share"
        ];
      };
    };

    systemd.timers.trash-empty = {
      description = "Timer for the trash retention purge";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "daily";
        # 分散執行時間,避免同時喚醒磁碟。
        RandomizedDelaySec = "15min";
        # 錯過的清理在開機後補跑。
        Persistent = true;
      };
    };
  };
}
