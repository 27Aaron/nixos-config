{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.hardware'.persistence;
  user = vars.username;

  # Home Manager 透過 persist' 回報的狀態;未載入 HM 時為空。
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

    # initrd 就要掛上持久分割區,才能及早提供 machine-id。
    fileSystems."/persistent".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persistent".commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];
    };

    # 基本使用者狀態,各模組與 Home Manager 回報的項目附加在後。
    preservation'.user.directories = [
      # 不整體保留 ~/.cache:內容幾乎都可重建且成長很快,需要的快取由各模組
      # 自行登記。

      # GPG 金鑰環;GNOME 鑰匙圈見 home/base/gui/seahorse.nix。
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
          # DynamicUser 服務的 StateDirectory。
          directory = "/var/lib/private";
          mode = "0700";
        }
        {
          directory = "/var/lib/machines";
          mode = "0700";
        }
        "/var/log"
        {
          # 放在持久卷以免佔用根 tmpfs;所有人可寫,比照 /tmp 加上 nosuid、nodev。
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

    # 持久化的 /var/lib/lastlog 與 lastlog2 的 tmpfiles 規則衝突,以空檔覆蓋。
    environment.etc."tmpfiles.d/lastlog2-tmpfiles.conf".text = ''
      # Managed by Preservation.
    '';

    # /var/tmp 在持久卷上,開機時清空(systemd 預設只清 30 天前的檔案)。
    systemd.tmpfiles.rules = [
      "D! /var/tmp 1777 root root"
    ];

    # bind 掛載配方下 systemd-machine-id-commit 必然失敗且無作用,予以抑制。
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };
}
