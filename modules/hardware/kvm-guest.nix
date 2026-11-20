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
  # 各 KVM 客體機共用的硬體基線;hosts/*/hardware.nix 只寫差異,例如盤符與是否經 clevis 解鎖。
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

    # 無螢幕的 VM 用 systemd-networkd,靜態位址寫在各主機的 network.nix。
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

    hardware'.grub.enable = lib.mkDefault true;
    # 沒有 LUKS 的機器用不到 initrd 裡的 SSH。
    server'.initrd-ssh.enable = lib.mkDefault true;

    services'.zram = {
      enable = true;
      memoryPercent = 500;
      memoryMax = cfg.zramMemoryMax;
    };

    hardware' = {
      disable-balloon.enable = true;
      disko = {
        enable = true;
        device = cfg.diskDevice;
        tmpfsSize = lib.mkDefault "512M";
        # 用 mkDefault 讓不加密磁碟或以 UEFI/systemd-boot 安裝的機器關閉,
        # 例如 janus 以 systemd-boot 裝在既有 ESP 上,沒有 BIOS 開機分割區。
        bios.enable = lib.mkDefault true;
        luks.enable = lib.mkDefault true;
      };
      persistence.enable = true;
    };

    # Proxmox 透過 guest agent 正常關機並回報 IP。
    services.qemuGuest.enable = true;
  };
}
