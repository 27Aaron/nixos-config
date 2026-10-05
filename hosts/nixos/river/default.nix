{ ... }:
{
  imports = [ ./hardware.nix ];

  security'.firewall.enable = true;

  # The T2 controller exposes a USB Ethernet device that never gets a link, so
  # keep NetworkManager from retrying its automatic connection on every start.
  networking.networkmanager.unmanaged = [ "interface-name:enp2s0f1u1" ];

  services' = {
    networkmanager.enable = true;
    openssh.enable = true;
    vnstat.enable = true;
  };

  profiles = {
    nixos = [
      "server"
      "desktop"
      "ephemeral-root"
    ];

    home = [ "common" ];
  };

  system = "x86_64-linux";
  stateVersion = "26.05";
  timeZone = "Asia/Tokyo";
}
