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
    mosdns = {
      enable = true;
      remoteSocks5 = "192.168.2.1:7890";
    };

    openssh = {
      enable = true;
      rootLogin = true;
    };

    vnstat.enable = true;
  };

  system.stateVersion = "26.11";
}
