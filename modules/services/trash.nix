{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.services'.trash;
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

    # tmpfs 根之下,家目錄的回收桶重開機就沒了,但各掛載點裡的
    # .Trash-$uid(Downloads、Documents 等)隨目錄本身保留下來,
    # 而檔案總管不會把它們匯總顯示,於是可以無聲無息地長大。
    # 這個計時器統一清掉所有回收桶裡過期的項目。
    systemd.services.trash-empty = {
      description = "Purge trash items older than ${toString cfg.retentionDays} days";

      script = ''
        ${pkgs.trash-cli}/bin/trash-empty ${toString cfg.retentionDays} -f
      '';

      # 那些 .Trash-$uid 位於 preservation 的 bind 掛載之內,必須等掛載完成
      # 才掃得到。preservation 的 mount unit 帶 DefaultDependencies=no,
      # 本身不排在 local-fs.target 之後,因此兩個都列。
      after = [
        "local-fs.target"
        "preservation.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        User = vars.username;
        Environment = [
          "HOME=/home/${vars.username}"
          "XDG_DATA_HOME=/home/${vars.username}/.local/share"
        ];
      };
    };

    systemd.timers.trash-empty = {
      description = "Timer for the trash retention purge";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "daily";
        # 散開各主機的執行時間,避免同時喚醒磁碟。
        RandomizedDelaySec = "15min";
        # 關機或休眠期間錯過的清理,下次開機補跑。
        Persistent = true;
      };
    };
  };
}
