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

  # enableAllTerminfo pulls rxvt-unicode-unwrapped in, which no longer builds
  # with GCC 16 (its own lerp clashes with std::lerp), so keep it off.
  environment.enableAllTerminfo = false;

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

  # The T2 controller exposes a USB Ethernet device that never gets a link, so
  # keep NetworkManager from retrying its automatic connection on every start.
  networking.networkmanager.unmanaged = [ "interface-name:enp2s0f1u1" ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
