{
  # Headless machine: base system plus remote access.
  server = [
    ../../modules/common/nix.nix
    ../../modules/nixos/system/core.nix
    ../../modules/nixos/system/nix.nix
    ../../modules/nixos/system/shell.nix
    ../../modules/nixos/security/firewall.nix
    ../../modules/nixos/services/openssh.nix
    ../../modules/nixos/services/vnstat.nix
  ];

  # What a desktop adds on top of the server set: network management and
  # Bluetooth. Select both profiles on such a host. The user-facing modules come
  # from the home profile.
  desktop = [
    ../../modules/nixos/services/networkmanager.nix
    ../../modules/nixos/hardware/bluetooth.nix
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
