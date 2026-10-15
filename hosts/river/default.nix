{ ... }:

{
  imports = [
    ./hardware.nix
  ];

  time.timeZone = "Asia/Tokyo";

  core'.firewall.enable = true;

  services'.openssh.enable = true;
  services'.networkmanager.enable = true;
  services'.pipewire.enable = true;

  system.stateVersion = "26.05";
}
