{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware'.bluetooth.enable = true;
  hardware'.systemd-boot.enable = true;

  hardware.apple-t2 = {
    firmware = {
      enable = true;
      version = "sonoma";
    };
    kernelChannel = "latest";
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
