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

    # /tmp 放磁碟,不與根共用 tmpfs:一次解大壓縮檔就把根吃滿,而根一滿是整個
    # 系統癱掉。代價是跨重啟累積,因此搭配 boot.tmp.cleanOnBoot 在開機時清空。
    # 既有機器不必重灌,建立 subvolume 後重開機即可(nofail 讓它還沒建立時
    # 退回根 tmpfs,不至於開不了機):
    #   sudo btrfs subvolume create /btr_pool/@tmp
    # 權限 1777 由 cleanOnBoot 設定;但「先 switch 才手動掛載」時 tmpfiles 已
    # 跑完,得自己 chmod 1777 /tmp。
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
  # GPT partlabel 由屬性名生成(disk-main-<name>)。加密時沿用既有磁碟的 luks
  # 標籤,改名會使 crypttab 找不到設備。
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

    # cleanOnBoot 只追加一條開機 tmpfiles 規則(D! /tmp 1777 root root),不會改變
    # /tmp 的位置——只有 /tmp 在磁碟上時才有意義,與上面的 @tmp 成對使用。
    boot.tmp.cleanOnBoot = true;

    # 只讓 initrd 認得已登記的 FIDO2 鑰匙,不替磁碟登記;鑰匙是 USB HID,
    # 不放進 initrd 就看不到。操作對象是 /dev/disk/by-partlabel/disk-main-luks,
    # 不要對 /dev/mapper/crypted;每次只插一把鑰匙。列出槽位(槽 0 通常是密碼),
    # 或加 --password 增設密碼槽:
    #   sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-main-luks
    # 加 FIDO2(預設要 PIN 再觸摸;加 --fido2-with-client-pin=no 則只觸摸):
    #   sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-main-luks
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
                          # 不必空等預設的 30 秒。單位是秒。
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
