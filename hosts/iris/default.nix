{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  services' = {
    mosdns.enable = true;
    adguardhome.enable = true;
    adguardhome.webPort = 80;

    openssh.enable = true;
    openssh.rootLogin = true;

    vnstat.enable = true;
  };

  system.stateVersion = "26.11";
}
