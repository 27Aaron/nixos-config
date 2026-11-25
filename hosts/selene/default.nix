{
  imports = [
    ./hardware.nix
    ./power.nix
    ./storage.nix
  ];

  services' = {
    avahi.enable = true;
    networkmanager.enable = true;
    openssh.enable = true;
    openssh.rootLogin = true;
    vnstat.enable = true;
  };

  system.stateVersion = "23.05";
}
