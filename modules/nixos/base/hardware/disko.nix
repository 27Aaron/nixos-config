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

    # /tmp 放在磁碟而非根 tmpfs,解壓大檔時才不會撐滿根目錄;開機時由
    # cleanOnBoot 清空。nofail 讓尚未建立此 subvolume 的機器仍可開機:
    #   sudo btrfs subvolume create /btr_pool/@tmp
    "@tmp" = {
      mountpoint = "/tmp";
      mountOptions = btrfsOptions ++ [
        "nosuid"
        "nodev"
        "nofail"
      ];
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
  # GPT partlabel 由屬性名生成(disk-main-<name>),改名會讓 crypttab 找不到裝置。
  dataPartitionName = if cfg.luks.enable then "luks" else "data";
in
{
  options.hardware'.disko = {
    enable = lib.mkEnableOption "the disko-managed ephemeral NixOS layout";

    device = lib.mkOption {
      type = lib.types.str;
      description = "Disk to format; prefer a stable /dev/disk/by-id/ path.";
    };

    tmpfsSize = lib.mkOption {
      type = lib.types.str;
      default = "4G";
      description = "Size of the ephemeral root tmpfs.";
    };

    espSize = lib.mkOption {
      type = lib.types.str;
      default = "256M";
      description = "Size of the EFI system partition.";
    };

    swapSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Btrfs swapfile size; null disables it.";
    };

    luks.enable = lib.mkEnableOption "LUKS encryption for the data partition";

    luks.fido2.enable = lib.mkEnableOption ''
      FIDO2 unlocking for the LUKS partition. This only lets the initrd use a
      key that is already enrolled; enroll one by hand with
      systemd-cryptenroll, as the comment in this module describes
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

    # 只在開機時清空 /tmp,不改變其位置;與上方的 @tmp 搭配。
    boot.tmp.cleanOnBoot = true;

    # 下方的 crypttabExtraOpts 只有 systemd initrd 會讀取。
    #
    # FIDO2 解鎖需要 USB HID 驅動。登記需手動,對分割區而非 /dev/mapper/crypted
    # 操作,每次只插一把鑰匙;預設要求 PIN 與觸摸,單有鑰匙無法解鎖:
    #   sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-main-luks   # 列出槽位
    #   sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-main-luks
    boot.initrd = lib.mkIf cfg.luks.enable {
      systemd.enable = true;
      availableKernelModules = lib.optionals cfg.luks.fido2.enable [
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
                          # 未插鑰匙時 5 秒後改用密碼,預設要等 30 秒。
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
