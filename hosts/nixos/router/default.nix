# Router - NixOS VM on Proxmox (4 vCPU, 1 GB RAM, 32 GB disk)
{ ... }:
{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  # Avoid concurrent local builds exhausting the VM's 1 GB memory limit.
  nix.settings.max-jobs = 1;

  services' = {
    fail2ban.enable = true;
    openssh.enable = true;
    vnstat.enable = true;
    zram.enable = true;
  };

  security'.firewall.enable = true;

  profiles = {
    nixos = [
      "server"
      "ephemeral-root"
    ];
  };

  system = "x86_64-linux";
  stateVersion = "26.05";
}
