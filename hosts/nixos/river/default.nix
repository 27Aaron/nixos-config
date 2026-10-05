{ ... }:
{
  imports = [ ./hardware.nix ];

  security'.firewall.enable = true;

  services' = {
    networkmanager.enable = true;
    openssh.enable = true;
    vnstat.enable = true;
  };

  # This host has no use for IPv6.
  networking.enableIPv6 = false;

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
