# Hardware profile for the MECHREVO WUJIE14XA (Wujie 14X Blizzard) laptop.
#
#   DMI        MECHREVO WUJIE14XA, board WUJIE14-GX4HRXL, BIOS N.1.14MRO50
#   CPU        AMD Ryzen 7 8845HS (Phoenix / Hawk Point), 8C/16T
#   Memory     2 x 16 GB DDR5-5600, Crucial/Micron CT16G56C46S5.C8D
#   GPU        Radeon 780M (HawkPoint1)                  [1002:1900]
#   Wi-Fi      MediaTek MT7922 (RZ616), mt7921e          [14c3:7922]
#   Bluetooth  13d3:3585, the Bluetooth half of the MT7922
#   Ethernet   Motorcomm YT6801, needs Linux >= 7.0      [1f0a:6801]
#   Touchpad   UNIW0001:00 093A:0255, on I2C rather than PS/2
#   Audio      Radeon HD Audio + Ryzen HD Audio          [1002:1640], [1022:15e3]
#   USB4       single-cable USB-C display output works   [1022:1669]
#   Storage    Micron 2550 NVMe SSD, 1 TB
#   TPM        present (/dev/tpm0)
#   Sensors    k10temp, amdgpu, nvme, BAT0, spd5118 x2
#   Power      s2idle only
#   Webcam     IR camera                                 [04f2:b7dd]
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

  # 開機:載入器、核心與 initrd。
  hardware'.systemd-boot.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # 開機畫面不顯示 ACPI 這類錯誤,記錄仍在 journal 裡。
    consoleLogLevel = 3;

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
  };

  # 韌體與週邊驅動。
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.brightness.enable = true;
}
