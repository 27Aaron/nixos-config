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

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

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

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # 休眠:從 LUKS 加密的 swapfile 恢復。偏移量是 /swap/swapfile 在設備上
    # 以 4K 塊計的物理起點。若 swapfile 被搬動過(btrfs balance/defrag、重建),
    # 用以下命令重新測量:
    #   sudo "$(nix build nixpkgs#e2fsprogs --no-link --print-out-paths | head -1)/bin/filefrag" \
    #     -v /swap/swapfile | awk '$1=="0:" {gsub("\\.", "", $4); print $4}'
    resumeDevice = "/dev/mapper/crypted";
    kernelParams = [ "resume_offset=269568" ];
  };

  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_24364AD5D8E0";
    espSize = "1G";
    swapSize = "32769M";
    luks.enable = true;
  };
  hardware'.systemd-boot.enable = true;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.persistence.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
