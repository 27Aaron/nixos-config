{ ... }:

{
  imports = [
    ./hardware.nix
  ];

  core'.firewall.enable = true;

  desktop' = {
    greetd.enable = true;
    niri.enable = true;
  };

  services'.openssh.enable = true;
  services'.networkmanager.enable = true;
  services'.pipewire.enable = true;

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "26.05";
}
