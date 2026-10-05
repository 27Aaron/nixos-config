# MacBook Pro 2018 13-inch (Intel Core i5-8259U, 8 GB RAM, 512 GB SSD)
{ ... }:
{
  imports = [ ./hardware.nix ];

  desktop' = {
    fcitx5.enable = true;
    fonts.enable = true;
    greetd.enable = true;
    niri.enable = true;
    noctalia.enable = true;
  };

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

    home = [
      "common"
      "desktop"
    ];
  };

  system = "x86_64-linux";
  stateVersion = "26.05";
  timeZone = "Asia/Tokyo";
}
