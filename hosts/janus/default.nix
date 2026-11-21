{
  imports = [
    ./disko.nix
    ./hardware.nix
    ./network.nix
  ];

  services' = {
    avahi.enable = true;
    mihomo = {
      enable = true;
      allowLan = true;
    };
    openssh = {
      enable = true;
      rootLogin = true;
    };
    vnstat.enable = true;
  };

  system.stateVersion = "26.05";
}
