{
  imports = [
    ./hardware.nix
    ./power.nix
    ./storage.nix
  ];

  services' = {
    avahi.enable = true;
    networkmanager.enable = true;
    openssh = {
      enable = true;
      rootLogin = true;
    };
    vnstat.enable = true;
  };

  server'.fail2ban.enable = true;

  dev' = {
    project-env.enable = true;
    toolchain.enable = true;
  };

  system.stateVersion = "23.05";
}
