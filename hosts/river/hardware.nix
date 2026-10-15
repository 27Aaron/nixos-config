{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 磁碟與檔案系統佈局(ESP、LUKS、Btrfs、swapfile)。
  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_24364AD5D8E0";
    espSize = "1G";
    swapSize = "32769M";
    luks.enable = true;
  };

  # 開機:載入器、核心與 initrd、休眠。
  hardware'.systemd-boot.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    initrd = {
      # preservation 的硬性需求;同時讓 LUKS 的 crypttab 選項生效。
      systemd.enable = true;

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    # 休眠:從 LUKS 加密的 swapfile 恢復。偏移量是 /swap/swapfile 在設備上
    # 以 4K 塊計的物理起點。若 swapfile 被搬動過(btrfs balance/defrag、重建),
    # 用以下命令重新測量:
    #   sudo "$(nix build nixpkgs#e2fsprogs --no-link --print-out-paths | head -1)/bin/filefrag" \
    #     -v /swap/swapfile | awk '$1=="0:" {gsub("\\.", "", $4); print $4}'
    resumeDevice = "/dev/mapper/crypted";
    kernelParams = [ "resume_offset=269568" ];
  };

  # 韌體與週邊驅動。
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;

  # 狀態持久化。
  hardware'.persistence.enable = true;

  # 與本機硬體綁定的服務:電源管理、壓縮 swap、磁碟健康與 Btrfs 維護。
  services' = {
    # 電源
    power-profiles-daemon.enable = true;
    upower.enable = true;

    # 壓縮 swap
    zram = {
      enable = true;
      # 上限 16G(記憶體不足 16G 時則用滿記憶體)
      memoryPercent = 100;
      memoryMax = 16 * 1024 * 1024 * 1024;
    };

    # 磁碟健康與 Btrfs 維護
    smartd.enable = true;
    btrfs-scrub.enable = true;
    btrbk.enable = true;
  };
}
