{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.kernelParams = [
    # Use the classic interface name expected by the network configuration.
    "net.ifnames=0"
    # The audit log is noise on this home router VM.
    "audit=0"
  ];

  hardware'.systemd-boot.enable = true;

  # The VM has a 256M ESP; keep fewer generations so it does not fill up.
  boot.loader.systemd-boot.configurationLimit = 4;

  # Prevent host ballooning from starving the router VM.
  hardware'.disable-balloon.enable = true;

  # PVE uses the guest agent for clean shutdown and IP reporting.
  services.qemuGuest.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware'.disko = {
    enable = true;
    device = "/dev/sda";
    tmpfsSize = "512M";
  };

  hardware'.persistence.enable = true;
}
