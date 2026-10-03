{
  system = "x86_64-linux";

  modules = [
    ../../../../profiles/nixos/server.nix
    ./configuration.nix
    ./hardware.nix
    ./network.nix
  ];
}
