{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    # net.ifnames=0 gives the NIC a classic eth0 name; audit=0 silences the
    # kernel audit log, which is pure noise on a home router VM.
    kernelParams = [
      "audit=0"
      "net.ifnames=0"
    ];
  };

  hardware'.systemd-boot.enable = true;

  # Keep the balloon driver disabled: the host reclaiming memory from this VM
  # would starve the router.
  hardware'.disable-balloon.enable = true;

  # PVE uses the guest agent for clean shutdown and IP reporting.
  services.qemuGuest.enable = true;

  # Ephemeral tmpfs root backed by preservation on a dedicated data partition.
  hardware'.disko = {
    enable = true;
    device = "/dev/sda";
    espSize = "256M";
    tmpfsSize = "512M";
  };

  hardware'.persistence.enable = true;
}
