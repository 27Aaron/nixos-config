{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.disko;

  btrfsOptions = [
    "compress=zstd:1"
    "discard=async"
    "noatime"
  ];

  subvolumes = {
    "@nix" = {
      mountpoint = "/nix";
      mountOptions = btrfsOptions;
    };

    "@persistent" = {
      mountpoint = "/persistent";
      mountOptions = btrfsOptions;
    };

    "@snapshots" = {
      mountpoint = "/snapshots";
      mountOptions = btrfsOptions;
    };
  }
  // lib.optionalAttrs (cfg.swapSize != null) {
    "@swap" = {
      mountpoint = "/swap";
      swap.swapfile.size = cfg.swapSize;
    };
  };

  btrfs = {
    type = "btrfs";
    extraArgs = [
      "-f"
      "--csum"
      "xxhash64"
      "--label"
      "NixOS"
    ];
    mountpoint = "/btr_pool";
    mountOptions = [
      "noatime"
      "subvolid=5"
    ];
    inherit subvolumes;
  };
  # GPT partlabel 由分割區屬性名生成(disk-main-<name>)。
  # 加密時沿用既有磁碟的 luks 標籤,改名會使 crypttab 找不到設備。
  dataPartitionName = if cfg.luks.enable then "luks" else "data";
in
{
  options.hardware'.disko = {
    enable = lib.mkEnableOption "the disko-managed ephemeral NixOS layout";

    device = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path to the main disk to format, ideally a stable path such as
        /dev/disk/by-id/.
      '';
    };

    tmpfsSize = lib.mkOption {
      type = lib.types.str;
      default = "4G";
      description = "The size of the ephemeral root filesystem.";
    };

    espSize = lib.mkOption {
      type = lib.types.str;
      default = "256M";
      description = "The size of the EFI system partition.";
    };

    swapSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The Btrfs swapfile size, or null to disable it.";
    };

    luks.enable = lib.mkEnableOption "LUKS encryption for the data partition";

    luks.fido2.enable = lib.mkEnableOption ''
      FIDO2 unlocking for the LUKS partition. This only teaches the initrd to
      use an enrolled YubiKey. Enrollment is not done here: disko's own
      enrollFido2 runs while formatting the disk
    '';

    bios.enable = lib.mkEnableOption "a BIOS boot partition for GRUB";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.luks.fido2.enable -> cfg.luks.enable;
        message = "hardware'.disko.luks.fido2.enable requires hardware'.disko.luks.enable.";
      }
    ];

    # FIDO2 權杖在 LUKS 頭部,開機時由 systemd-cryptsetup 讀取。
    # 這裡只讓 initrd 認得已登記的鑰匙,不會替磁碟登記。
    # 鑰匙是 USB HID,不放進 initrd 就看不到。
    #
    # 操作對象是 /dev/disk/by-partlabel/disk-main-luks,不要對 /dev/mapper/crypted。
    # 每次只插一把鑰匙。查看槽位(槽 0 通常是密碼):
    #   sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-main-luks
    # 添加密碼槽(先驗證現有密碼,再輸入要新增的密碼):
    #   sudo systemd-cryptenroll --password /dev/disk/by-partlabel/disk-main-luks
    # 添加 FIDO2,開機要 FIDO2 PIN 再觸摸:
    #   sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-main-luks
    # 添加 FIDO2,只觸摸、不設 PIN:
    #   sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=no /dev/disk/by-partlabel/disk-main-luks
    boot.initrd = lib.mkIf cfg.luks.fido2.enable {
      systemd.enable = true;
      availableKernelModules = [
        "usbhid"
        "hid_generic"
      ];
    };

    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=755"
          "nodev"
          "nosuid"
          "size=${cfg.tmpfsSize}"
        ];
      };

      disk.main = {
        type = "disk";
        device = cfg.device;

        content = {
          type = "gpt";
          partitions =
            lib.optionalAttrs cfg.bios.enable {
              BIOS = {
                priority = 0;
                size = "1M";
                type = "EF02";
              };
            }
            // {
              ESP = {
                priority = 1;
                size = cfg.espSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  extraArgs = [
                    "-n"
                    "BOOT"
                  ];
                  mountOptions = [ "umask=0077" ];
                };
              };

              ${dataPartitionName} = {
                priority = 2;
                size = "100%";
                # 8309 = Linux LUKS;無加密時為 8300 = Linux filesystem。
                type = if cfg.luks.enable then "8309" else "8300";
                content =
                  if cfg.luks.enable then
                    {
                      type = "luks";
                      name = "crypted";
                      settings = {
                        allowDiscards = true;
                        bypassWorkqueues = true;
                        crypttabExtraOpts = [
                          "same-cpu-crypt"
                          "submit-from-crypt-cpus"
                        ]
                        ++ lib.optionals cfg.luks.fido2.enable [
                          "fido2-device=auto"
                          # 鑰匙沒插上時不必空等預設的 30 秒。數值單位是秒。
                          "token-timeout=5"
                        ];
                      };
                      content = btrfs;
                    }
                  else
                    btrfs;
              };
            };
        };
      };
    };
  };
}
