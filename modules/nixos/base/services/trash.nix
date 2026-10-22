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

    # tmpfs 根之下家目錄的回收桶重開機就沒了,但各掛載點裡的 .Trash-$uid
    # 隨目錄本身留下來,而檔案總管不會匯總顯示,於是無聲無息地長大。
    systemd.services.trash-empty = {
      description = "Purge trash items older than ${toString cfg.retentionDays} days";

      script = ''
        ${pkgs.trash-cli}/bin/trash-empty ${toString cfg.retentionDays} -f
      '';

      # .Trash-$uid 位於 preservation 的 bind 掛載之內,要等掛載完成才掃得到。
      # preservation 的 mount unit 帶 DefaultDependencies=no,不排在
      # local-fs.target 之後,所以兩個都列。
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
