{
  imports = [
    ../../modules/common/nix.nix
    ../../modules/nixos/system/core.nix
    ../../modules/nixos/system/nix.nix
    ../../modules/nixos/security/firewall.nix
    ../../modules/nixos/services/networkmanager.nix
    ../../modules/nixos/services/openssh.nix
    ../../modules/nixos/services/vnstat.nix
  ];

  security'.firewall.enable = true;
  services' = {
    networkmanager.enable = true;
    openssh.enable = true;
    vnstat.enable = true;
  };
}
