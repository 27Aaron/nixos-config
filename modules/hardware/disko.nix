{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.hardware'.disko;

  btrfsOptions = [
    "compress=zstd"
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
  # 遊戲庫可以重新下載,獨立成 subvolume 才不會被 btrbk 隨 @persistent 快照,
  # 每次遊戲更新都留下數十 GB 的舊版本。新 subvolume 的根目錄屬於 root,
  # 建立後要交給使用者一次;擁有者存在 Btrfs 上,不必每次開機設定:
  #   sudo btrfs subvolume create /btr_pool/@games
  #   sudo chown <user>:users /btr_pool/@games && sudo chmod 0700 /btr_pool/@games
  // lib.optionalAttrs cfg.games.enable {
    "@games" = {
      mountpoint = "/games";
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
  imports = [ inputs.disko.nixosModules.default ];

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

    games.enable = lib.mkEnableOption "a Btrfs subvolume at /games for game libraries, kept out of snapshots";

    luks.enable = lib.mkEnableOption "LUKS encryption for the data partition";

    luks.fido2.enable = lib.mkEnableOption ''
      FIDO2 unlocking for the LUKS partition. This only lets the initrd use a
      key that is already enrolled; enroll one by hand with
      systemd-cryptenroll, as the comment in this module describes
    '';

    luks.tpm2.enable = lib.mkEnableOption ''
      TPM2 unlocking for the LUKS partition, tried before FIDO2 and the passphrase.
      Like FIDO2, this only lets the initrd use a key that is already enrolled, bound
      to PCR 7, so it requires Secure Boot through hardware'.lanzaboote
    '';

    bios.enable = lib.mkEnableOption "a BIOS boot partition for GRUB";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.luks.fido2.enable -> cfg.luks.enable;
        message = "hardware'.disko.luks.fido2.enable requires hardware'.disko.luks.enable.";
      }
      {
        assertion = cfg.luks.tpm2.enable -> cfg.luks.enable;
        message = "hardware'.disko.luks.tpm2.enable requires hardware'.disko.luks.enable.";
      }
      {
        # 沒有 Secure Boot 時,PCR 7 不會因換掉 initrd 而改變,TPM 會照樣交出金鑰。
        assertion = cfg.luks.tpm2.enable -> config.hardware'.lanzaboote.enable;
        message = "hardware'.disko.luks.tpm2.enable requires Secure Boot through hardware'.lanzaboote.";
      }
    ];

    boot.tmp.cleanOnBoot = true;

    # FIDO2 解鎖需要 USB HID 驅動。
    #
    # 登記對分割區操作,不是 /dev/mapper/crypted。開機依序嘗試 TPM2、FIDO2,
    # 最後才問密碼;密碼槽位要保留作備援。
    #
    # FIDO2 一次只插一把,預設要 PIN 與觸摸;沒有鍵盤的主機加上
    # --fido2-with-client-pin=no(見 WA-022):
    #   sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-main-luks
    #
    # TPM2 只綁 PCR 7,系統更新不必重新登記;換 Secure Boot 金鑰後加上
    # --wipe-slot=tpm2 重新登記。不加 --tpm2-with-pin=yes 時開機不需任何秘密,
    # 主機就不能自動登入,睡眠前也必須鎖定:
    #   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks
    boot.initrd.availableKernelModules = lib.optionals (cfg.luks.enable && cfg.luks.fido2.enable) [
      "usbhid"
      "hid_generic"
    ];

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
                        ++ lib.optionals cfg.luks.tpm2.enable [ "tpm2-device=auto" ]
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
