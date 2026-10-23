{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  # 硬體清單與 PCI ID 見同目錄的 README.md。
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 開機:載入器、核心與 initrd。systemd initrd 由 disko 與 persistence
  # 模組啟用。
  hardware'.lanzaboote.enable = true;

  boot = {
    # Motorcomm YT6801 乙太網路需要 Linux 7.0 以上。
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];

    # 開機畫面不顯示 ACPI 這類錯誤,記錄仍在 journal 裡。
    # 移除條件見 WORKAROUNDS.md 的 WA-004。
    consoleLogLevel = 3;

    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
    ];
  };

  # 韌體與週邊驅動。
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.brightness.enable = true;
}
