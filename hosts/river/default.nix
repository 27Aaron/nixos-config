{ ... }:

{
  imports = [
    ./hardware.nix
  ];

  core'.firewall.enable = true;
  core'.sops.enable = true;

  desktop'.greetd.enable = true;
  desktop'.niri.enable = true;
  desktop'.niri.autoLogin = true;
  desktop'.fcitx5.enable = true;
  desktop'.noctalia.enable = true;
  desktop'.fonts.enable = true;

  services'.dae.enable = true;
  services'.openssh.enable = true;
  services'.networkmanager.enable = true;
  services'.pipewire.enable = true;
  services'.vnstat.enable = true;

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "26.05";
}
