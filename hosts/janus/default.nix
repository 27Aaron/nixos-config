{
  imports = [
    ./disko.nix
    ./hardware.nix
    ./network.nix
  ];

  services' = {
    avahi.enable = true;
    dae = {
      enable = true;
      lanInterface = "eth0";
    };
    openssh = {
      enable = true;
      rootLogin = true;
    };
    vnstat.enable = true;
  };

  system.stateVersion = "26.05";
}
