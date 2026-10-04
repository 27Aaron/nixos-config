{
  imports = [
    ./server.nix
    ../../modules/nixos/hardware/bluetooth.nix
  ];

  hardware'.bluetooth.enable = true;
}
