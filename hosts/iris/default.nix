{
  imports = [
    ./disko.nix
    ./hardware.nix
    ./network.nix
  ];

  services' = {
    avahi.enable = true;

    adguardhome = {
      enable = true;
      webPort = 80;
    };
    mosdns.enable = true;

    openssh = {
      enable = true;
      rootLogin = true;
    };

    vnstat.enable = true;
  };

  system.stateVersion = "26.11";
}
