{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.podman;

  pruneFlags = [
    "--all"
    "--filter=until=168h"
  ];

  # drop-in 的 OnCalendar 會疊加在上游的 daily 上,要先清空。
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

      # 只做指令別名、不開 /run/docker.sock,登入帳號也不加入 podman 群組:
      # 連得上 rootful socket 就等於 root。
      dockerCompat = true;

      # 以 root 執行,只清 rootful 的儲存。
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = pruneFlags;
      };
    };

    virtualisation.containers = {
      # k8s-file 預設不限大小;journald 有統一的上限。
      containersConf.settings.containers.log_driver = "journald";

      # 上游預設沒有搜尋清單,nginx 這類短名稱會解析失敗。
      registries.settings.unqualified-search-registries = [ "docker.io" ];
    };

    # 系統層的計時器只更新 rootful 容器。
    systemd.timers.podman-auto-update = autoUpdateTimer;
    systemd.user.timers.podman-auto-update = autoUpdateTimer;

    systemd.user.services.podman-prune = {
      description = "Prune rootless Podman resources";
      # NixOS 服務自帶的 PATH 沒有 setuid 的 newuidmap。
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

    # rootful 容器發布的埠經 DNAT 走 forward 鏈,input 的防火牆擋不到,
    # filterForward 也會放行;rootless 的埠綁在主機上,不受影響。
    networking.nftables.tables.podman-published = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter; policy accept;
          ct status dnat oifname "podman*" iifname != "podman*" drop
        }
      '';
    };

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/var/lib/containers";
        mode = "0700";
      }
      # rootful 的自訂網路;NixOS 只在預設網路有自訂設定時才管理這裡。
      "/etc/containers/networks"
    ];

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".local/share/containers";
        mode = "0700";
      }
    ];
  };
}
