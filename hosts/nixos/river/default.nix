{ ... }:
{
  imports = [ ./hardware.nix ];

  security'.firewall.enable = true;

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
