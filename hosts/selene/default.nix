{
  imports = [
    ./hardware.nix
    ./power.nix
    ./storage.nix
  ];

  development' = {
    project-env.enable = true;
    toolchain.enable = true;
    claude-code.enable = true;
  };

  services' = {
    avahi.enable = true;
    networkmanager.enable = true;
    openssh.enable = true;
    openssh.rootLogin = true;
    vnstat.enable = true;
  };

  system.stateVersion = "23.05";
}
