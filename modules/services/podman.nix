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

  # drop-in 的 OnCalendar 會疊加在上游的 daily 之上,要先以空字串清掉。
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

      # 只做 docker 指令別名,不開 /run/docker.sock:連得上 rootful socket 就等於
      # root,所以登入帳號也不加入 podman 群組。
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

      # 不完整的映像名稱只到 Docker Hub 找。上游預設沒有搜尋清單,nginx 這類
      # 名稱會直接解析失敗;只列一個來源,也不會有同名映像該選哪個的問題。
      registries.settings.unqualified-search-registries = [ "docker.io" ];
    };

    # 系統層的計時器只更新 rootful 容器。
    systemd.timers.podman-auto-update = autoUpdateTimer;
    systemd.user.timers.podman-auto-update = autoUpdateTimer;

    systemd.user.services.podman-prune = {
      description = "Prune rootless Podman resources";
      # newuidmap 是 /run/wrappers/bin 的 setuid 程式;NixOS 產生的服務會以自己
      # 的 PATH 蓋掉使用者管理器的預設值。
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

    # rootful 容器發布的埠經 DNAT 走 forward 鏈,不經過 input,主機防火牆擋不到,
    # NixOS 的 filterForward 也會直接放行 DNAT。只擋從外部進來的;主機自己與其他
    # 容器仍連得到。rootless 的埠由 pasta 綁在主機上,照常受 input 鏈管制。
    networking.nftables.tables.podman-published = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter; policy accept;
          ct status dnat oifname "podman*" iifname != "podman*" drop
        }
      '';
    };

    # rootful 自訂網路(podman1 起)的 aardvark-dns 聽在閘道上,查詢會進 input
    # 鏈;上游只替 podman0 開。firewall.interfaces 不加引號,無法用萬用字元。
    networking.firewall.extraInputRules = ''
      iifname "podman*" udp dport 53 accept
    '';

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/var/lib/containers";
        mode = "0700";
      }
      # rootful 的自訂網路設定;預設網路沒有自訂設定,NixOS 不會管理這個目錄。
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
