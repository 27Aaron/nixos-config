{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.hardware'.persistence;
  user = vars.username;

  # Home Manager 經由 persist' 回報要保留的狀態;沒載入 HM 模組時此橋接為空。
  persist =
    config.hm'.persist' or {
      directories = [ ];
      files = [ ];
    };
in
{
  # preservation 本體由 hosts/default.nix 引入,這裡只定義選項別名。
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
    # preservation 以 initrd 的 tmpfiles 掛載,需要 systemd initrd。
    boot.initrd.systemd.enable = true;

    # 持久分割區得在 initrd 就掛上,才讀得到 machine-id。
    fileSystems."/persistent".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persistent".commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];
    };

    # 基礎使用者狀態;各軟體模組與 Home Manager 回報的會附加在後。
    preservation'.user.directories = [
      # 不整體持久化 ~/.cache:幾乎全是可重建內容且成長很快(實測 3.6G,光
      # 瀏覽器快取就 1.7G),留在 tmpfs 上重開機即清空。需要跨重啟的快取由
      # 各模組自行登記。

      # 沒有專屬模組可歸的 GPG 金鑰環。鑰匙環見 home/base/gui/seahorse.nix。
      {
        directory = ".gnupg";
        mode = "0700";
      }
    ]
    ++ persist.directories;

    preservation'.user.files = persist.files;

    # 通用 NixOS 系統狀態。
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
        {
          directory = "/var/lib/machines";
          mode = "0700";
        }
        "/var/log"
        {
          # 放持久卷才不會吃掉根 tmpfs;世界可寫,因此比照 /tmp 加 nosuid 與 nodev。
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

    # preservation 掛載的 /var/lib/lastlog 會遮住 lastlog2 套件的 tmpfiles 規則,
    # 換成空檔避免衝突。
    environment.etc."tmpfiles.d/lastlog2-tmpfiles.conf".text = ''
      # Managed by Preservation.
    '';

    # /var/tmp 在持久卷上,不清理會跨重啟累積(systemd 預設只清 30 天前的)。
    # D! 在開機時清空內容並保留目錄與權限,等同 boot.tmp.cleanOnBoot。
    systemd.tmpfiles.rules = [
      "D! /var/tmp 1777 root root"
    ];

    # 用 bind 掛載配方時 commit 式改寫只適用於 symlink 配方,該服務必然失敗,
    # 對本配置無關緊要,予以抑制。
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };
}
