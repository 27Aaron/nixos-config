rec {
  # Shared base every NixOS host gets.
  base = [
    ../../modules/common/nix.nix
    ../../modules/nixos/system/core.nix
    ../../modules/nixos/system/nix.nix
    ../../modules/nixos/system/shell.nix
  ];

  # Headless machine: remote access and network accounting.
  server = base ++ [
    ../../modules/nixos/security/firewall.nix
    ../../modules/nixos/services/networkmanager.nix
    ../../modules/nixos/services/openssh.nix
    ../../modules/nixos/services/vnstat.nix

    {
      security'.firewall.enable = true;
      services' = {
        networkmanager.enable = true;
        openssh.enable = true;
        vnstat.enable = true;
      };
    }
  ];

  # Machine someone sits in front of; the user-facing modules come from the
  # home profile.
  desktop = server ++ [
    ../../modules/nixos/hardware/bluetooth.nix

    { hardware'.bluetooth.enable = true; }
  ];

  # Ephemeral tmpfs root backed by preservation, plus both boot loaders so the
  # host only sets the one it uses.
  ephemeral-root = [
    ../../modules/nixos/hardware/disko.nix
    ../../modules/nixos/hardware/persistence.nix
    ../../modules/nixos/hardware/boot/systemd-boot.nix
    ../../modules/nixos/hardware/boot/grub.nix
  ];
}
