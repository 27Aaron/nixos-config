{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.btrbk;
in
{
  options.services'.btrbk = {
    enable = lib.mkEnableOption "local Btrfs snapshots with btrbk";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr "/btr_pool" config.fileSystems;
        message = "the btrbk source volume must be a configured filesystem mount";
      }
      {
        assertion = builtins.hasAttr "/snapshots" config.fileSystems;
        message = "the btrbk snapshot directory must be a configured filesystem mount";
      }
    ];

    services.btrbk = {
      # 建立快照很快,但清理在筆電上應保持低調,尤其是開機追趕進度時。
      niceness = 15;
      ioSchedulingClass = "idle";

      instances.persistent = {
        onCalendar = "*-*-* 00,12:00:00";

        settings = {
          timestamp_format = "long-iso";
          snapshot_preserve_min = "24h";
          snapshot_preserve = "14d";

          volume."/btr_pool" = {
            snapshot_dir = "/snapshots";
            subvolume."@persistent".snapshot_create = "always";
          };
        };
      };
    };

    systemd.services.btrbk-persistent.unitConfig.RequiresMountsFor = [
      "/btr_pool"
      "/snapshots"
    ];

    # 服務使用者 btrbk 的家目錄,同時是它的 systemd StateDirectory。
    preservation'.os.directories = [
      {
        directory = "/var/lib/btrbk";
        user = "btrbk";
        group = "btrbk";
        mode = "0750";
      }
    ];
  };
}
