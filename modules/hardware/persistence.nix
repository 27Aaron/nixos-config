{
  config,
  inputs,
  lib,
  vars,
  ...
}:
let
  cfg = config.hardware'.persistence;
  user = vars.username;
in
{
  imports = [
    inputs.preservation.nixosModules.preservation
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
    # initrd 就要掛上持久分割區,才能及早提供 machine-id。
    fileSystems."/persistent".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persistent".commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];
    };

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

    # lastlog2 的 tmpfiles 規則與持久化的 /var/lib/lastlog 衝突;見 WA-010。
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
