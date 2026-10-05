{ ... }:
{
  imports = [
    ../../../profiles/nixos/desktop.nix
    ./hardware.nix
  ];

  environment.enableAllTerminfo = false;

  time.timeZone = "Asia/Tokyo";

  system.stateVersion = "26.05";
}
