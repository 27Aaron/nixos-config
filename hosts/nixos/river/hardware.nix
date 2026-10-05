{
  config,
  lib,
  modulesPath,
  nixosHardware,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    nixosHardware.nixosModules.apple-t2
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # The Apple T2 terminfo database is large; the SSH module would otherwise pull
  # it in for the whole system.
  environment.enableAllTerminfo = false;

  hardware'.bluetooth.enable = true;
  hardware'.systemd-boot.enable = true;

  hardware.apple-t2 = {
    firmware = {
      enable = true;
      version = "sonoma";
    };

    # "latest" maps to linux_7_0, which nixpkgs has dropped as end-of-life.
    kernelChannel = "stable";
  };

  hardware'.disko = {
    enable = true;
    device = "/dev/nvme0n1";
    espSize = "512M";
    swapSize = "16385M";
    tmpfsSize = "2G";
  };

  hardware'.persistence.enable = true;
}
