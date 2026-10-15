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

    bios.enable = lib.mkEnableOption "a BIOS boot partition for GRUB";
  };

  config = lib.mkIf cfg.enable {
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
                type = "8309";
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
