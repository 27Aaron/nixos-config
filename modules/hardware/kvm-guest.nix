{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.kvm-guest;
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  options.hardware'.kvm-guest = {
    enable = lib.mkEnableOption "the shared KVM guest baseline";

    diskDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/vda";
      description = "Disk for the disko layout. virtio disks show up as /dev/vda, SATA as /dev/sda.";
    };

    zramMemoryMax = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2 * 1024 * 1024 * 1024 + 1024 * 1024;
      description = "zram swap cap in bytes. Defaults to 2049 MiB (2 GiB + 1 MiB).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    networking = {
      useDHCP = false;
      useNetworkd = true;
    };

    services.resolved.enable = false;

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      kernelParams = [
        "audit=0"
        "net.ifnames=0"
      ];

      initrd = {
        compressor = "zstd";
        compressorArgs = [
          "-19"
          "-T0"
        ];
      };
    };

    hardware'.grub.enable = true;

    services'.zram = {
      enable = true;
      memoryPercent = 500;
      memoryMax = cfg.zramMemoryMax;
    };

    # /run 是 tmpfs,易失日誌直接吃客體機記憶體;持久日誌的模組預設 2G 對小磁碟的 VM 也偏多。
    core'.logging = {
      journalMaxUse = lib.mkDefault "256M";
      journalRuntimeMaxUse = lib.mkDefault "16M";
    };

    hardware' = {
      disko = {
        enable = true;
        device = cfg.diskDevice;
        tmpfsSize = lib.mkDefault "512M";
        bios.enable = true;
      };
      persistence.enable = true;
    };

    # 宿主機透過 balloon 回收記憶體時,會讓記憶體本來就少的 VM 不夠用。
    # 只靠 blacklist 擋不住明確的 modprobe,要同時有 install 規則。
    boot.blacklistedKernelModules = [ "virtio_balloon" ];
    boot.extraModprobeConfig = ''
      install virtio_balloon ${pkgs.coreutils}/bin/true
    '';

    # Proxmox 透過 guest agent 正常關機並回報 IP。
    services.qemuGuest.enable = true;
  };
}
