{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.hardware'.persistence;
  user = vars.username;

  # Home Manager 工具經由 persist' 回報它們保留的狀態。
  # 沒有載入任何 Home Manager 模組的主機,此橋接為空。
  persist =
    config.hm'.persist' or {
      directories = [ ];
      files = [ ];
    };
in
{
  # preservation 模組本體由 hosts/default.nix 統一引入,
  # 這裡只定義 preservation' 的選項別名。
  imports = [
    (lib.mkAliasOptionModule [ "preservation'" "os" ] [ "preservation" "preserveAt" "/persistent" ])
    (lib.mkAliasOptionModule
      [ "preservation'" "user" ]
      [ "preservation" "preserveAt" "/persistent" "users" user ]
    )
  ];

  options.hardware'.persistence = {
    enable = lib.mkEnableOption "Preservation for an ephemeral NixOS root";
  };

  config = lib.mkIf cfg.enable {
    # preservation 的 initrd 掛載(tmpfiles 規則)需要 systemd initrd。
    boot.initrd.systemd.enable = true;

    # preservation 需要在 initrd 階段掛載持久分割區,才能讀到 machine-id。
    fileSystems."/persistent".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persistent".commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];
    };

    # 基礎使用者狀態;Home Manager 工具經由 persist'
    # 回報的狀態會附加在後。
    preservation'.user.directories = [
      # 不整體持久化 ~/.cache。它幾乎全是可重建的內容,而且成長得很快
      # (實測 3.6G,其中瀏覽器 HTTP 快取就佔 1.7G)。留在 tmpfs 上,
      # 重開機即清空,順帶把「快取無限長大」這個問題一併消掉。
      #
      # 需要跨重啟的快取由各模組自行以 persist' 精確登記,
      # 目前只有 Nix 的求值與抓取快取(見 modules/nixos/base/core/nix.nix)。

      # Nix 與 Home Manager
      ".local/share/nix"
      ".local/state/home-manager"
      ".local/state/nix/profiles"

      # 沒有專屬模組管理的憑證放在這裡。
      {
        directory = ".gnupg";
        mode = "0700";
      }

      # 鑰匙環。
      {
        directory = ".local/share/keyrings";
        mode = "0700";
      }
    ]
    ++ persist.directories;

    preservation'.user.files = persist.files;

    # 基礎系統所需的通用 NixOS 狀態。
    preservation'.os = {
      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/lib/lastlog"
        "/var/lib/systemd"
        {
          # 動態使用者的 systemd 狀態(StateDirectory 服務)。
          directory = "/var/lib/private";
          mode = "0700";
        }
        # 容器與虛擬機器映像。
        {
          directory = "/var/lib/machines";
          mode = "0700";
        }
        "/var/log"
        {
          # 暫存區放在持久卷上,才不會吃掉根 tmpfs 的記憶體。
          # 它是世界可寫,因此比照 /tmp 加上 nosuid 與 nodev。
          directory = "/var/tmp";
          mode = "1777";
          mountOptions = [
            "nosuid"
            "nodev"
          ];
        }
      ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };

    # preservation 已建立並掛載 /var/lib/lastlog,遮住 lastlog2 套件
    # 針對同一目錄的 tmpfiles 規則,避免兩者衝突。
    environment.etc."tmpfiles.d/lastlog2-tmpfiles.conf".text = ''
      # Managed by Preservation.
    '';

    # /var/tmp 與 /tmp 都是可重建的暫存區,但 /var/tmp 位於持久卷,
    # 不清理就會跨重啟無限累積(systemd 預設只清 30 天前的項目)。
    # D! 在開機時清空內容並保留目錄與權限,效果等同 boot.tmp.cleanOnBoot。
    #
    # core dump 的清除與容量上限一併由 core'.logging 管理。
    systemd.tmpfiles.rules = [
      "D! /var/tmp 1777 root root"
    ];

    # systemd-machine-id-commit.service 會執行失敗,
    # 但對這種持久化 machine-id 的配置而言無關緊要,因此予以抑制。
    # (bind 掛載配方;commit 式改寫僅適用於 symlink 配方。)
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };
}
