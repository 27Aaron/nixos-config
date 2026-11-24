{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.kvm-guest;
  btrfsOptions = [
    "compress=zstd"
    "discard=async"
    "noatime"
  ];
in
{
  config = lib.mkIf cfg.disk.enable {
    boot.tmp.cleanOnBoot = true;

    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=755"
          "nodev"
          "nosuid"
          "size=512M"
        ];
      };

      disk.main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              priority = 0;
              size = "1M";
              type = "EF02";
            };
            esp = {
              priority = 1;
              size = "256M";
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
            root = {
              priority = 2;
              size = "100%";
              type = "8300";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "--csum"
                  "xxhash64"
                  "--label"
                  "NixOS"
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
                  "@tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = btrfsOptions ++ [
                      "nosuid"
                      "nodev"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
