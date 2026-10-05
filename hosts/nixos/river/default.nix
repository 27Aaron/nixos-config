{
  nixosHardware,
  ...
}:
{
  imports = [
    nixosHardware.nixosModules.apple-t2
    ../../../profiles/nixos/desktop.nix
    ../../../modules/nixos/hardware/disko.nix
    ../../../modules/nixos/hardware/persistence.nix
    ../../../modules/nixos/hardware/boot/grub.nix
    ../../../modules/nixos/hardware/boot/systemd-boot.nix
    ./hardware.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  environment.enableAllTerminfo = false;

  time.timeZone = "Asia/Tokyo";

  system.stateVersion = "26.05";
}
