{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.podman;

  # 只清掉一週內沒用到的映像與容器。
  pruneFlags = [
    "--all"
    "--filter=until=168h"
  ];

  # 上游計時器是每天一次。NixOS 把這裡的設定寫成 drop-in,而 drop-in 的
  # OnCalendar 會疊加在上游之上,要先以空字串清掉。
  autoUpdateTimer = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = [
      ""
      "*-*-* 00/6:00:00"
    ];
  };
in
{
  options.services'.podman = {
    enable = lib.mkEnableOption "the Podman container engine";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;

      # 只提供 docker 指令別名,不開 /run/docker.sock。rootful socket 屬於
      # podman 群組,能透過它取得 root,因此不把登入帳號加進去。
      dockerCompat = true;

      # 以 root 執行,只清 rootful 的儲存;rootless 的由下方的使用者服務清理。
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = pruneFlags;
      };
    };

    # k8s-file 預設不限大小,會在容器儲存裡一直長大;journald 有統一的上限。
    virtualisation.containers.containersConf.settings.containers.log_driver = "journald";

    # 只更新帶 io.containers.autoupdate 標籤、由 systemd 管理的容器。系統層
    # 的計時器只管 rootful 容器,rootless 的要另外啟用使用者層的同名計時器。
    systemd.timers.podman-auto-update = autoUpdateTimer;
    systemd.user.timers.podman-auto-update = autoUpdateTimer;

    systemd.user.services.podman-prune = {
      description = "Prune rootless Podman resources";
      # rootless podman 需要 /run/wrappers/bin 的 setuid newuidmap,而 NixOS
      # 產生的服務會以自己的 PATH 蓋掉使用者管理器的預設值。
      path = [ "/run/wrappers" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.concatStringsSep " " (
          [
            (lib.getExe config.virtualisation.podman.package)
            "system"
            "prune"
            "-f"
          ]
          ++ pruneFlags
        );
      };
      startAt = "weekly";
    };
    systemd.user.timers.podman-prune.timerConfig = {
      Persistent = true;
      RandomizedDelaySec = 1800;
    };

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/var/lib/containers";
        mode = "0700";
      }
    ];

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".local/share/containers";
        mode = "0700";
      }
    ];
  };
}
