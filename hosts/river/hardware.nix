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

  # systemd initrd 由 disko 與 persistence 模組啟用。
  hardware'.lanzaboote.enable = true;

  boot = {
    # Motorcomm YT6801 乙太網路需要 Linux 7.0 以上。
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];

    # 隱藏韌體的 ACPI 錯誤,journal 仍有紀錄;見 WA-004。
    consoleLogLevel = 3;

    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
    ];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.brightness.enable = true;
}
