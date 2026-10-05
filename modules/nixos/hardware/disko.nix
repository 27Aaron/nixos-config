{
  config,
  disko,
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
  }
  // lib.optionalAttrs (cfg.swapSize != null) {
    "@swap" = {
      mountpoint = "/swap";
      swap.swapfile.size = cfg.swapSize;
      mountOptions = btrfsOptions;
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
in
{
  imports = [ disko.nixosModules.disko ];

  options.hardware'.disko = {
    enable = lib.mkEnableOption "the disko-managed NixOS layout";

    device = lib.mkOption {
      type = lib.types.str;
      description = "The disk device used for the NixOS layout.";
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
          "relatime"
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

              data = {
                priority = 2;
                size = "100%";
                type = "8309";
                content =
                  if cfg.luks.enable then
                    {
                      type = "luks";
                      name = "crypted";
                      askPassword = true;
                      initrdUnlock = true;
                      settings = {
                        allowDiscards = true;
                        bypassWorkqueues = true;
                        crypttabExtraOpts = [
                          "same-cpu-crypt"
                          "submit-from-crypt-cpus"
                          "token-timeout=10"
                        ];
                      };
                      extraFormatArgs = [
                        "--type"
                        "luks2"
                        "--pbkdf"
                        "argon2id"
                      ];
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
