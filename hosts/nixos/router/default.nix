# Router - NixOS VM on Proxmox (4 vCPU, 1 GB RAM, 20 GB disk)
{ ... }:
{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  nix.settings.max-jobs = 1;

  services' = {
    fail2ban.enable = true;
    openssh.enable = true;
    vnstat.enable = true;
  };

  environment.enableAllTerminfo = false;
  security'.firewall.enable = true;

  profiles = {
    nixos = [
      "server"
      "ephemeral-root"
    ];
    home = [ "common" ];
  };

  system = "x86_64-linux";
  stateVersion = "26.05";
}
