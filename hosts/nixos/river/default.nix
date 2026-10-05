{ profiles, ... }:
{
  system = "x86_64-linux";
  stateVersion = "26.05";
  timeZone = "Asia/Tokyo";

  profiles = with profiles.nixos; [
    desktop
    ephemeral-root
  ];

  home = with profiles.home; [ common ];

  modules = [ ./hardware.nix ];
}
