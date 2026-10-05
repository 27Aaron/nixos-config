{
  # Headless machine: base system plus remote access, intrusion prevention
  # and compressed swap.
  server = [
    ../../modules/common/nix.nix
    ../../modules/nixos/system/core.nix
    ../../modules/nixos/system/nix.nix
    ../../modules/nixos/system/shell.nix
    ../../modules/nixos/security/firewall.nix
    ../../modules/nixos/services/openssh.nix
    ../../modules/nixos/services/vnstat.nix
    ../../modules/nixos/services/fail2ban.nix
    ../../modules/nixos/services/zram.nix
    ../../modules/nixos/hardware/disable-balloon.nix
  ];

  # What a desktop adds on top of the server set: network management, Bluetooth
  # and the Niri session with its greeter, shell and input method. Select both
  # profiles on such a host. The user-facing modules come from the home profile.
  desktop = [
    ../../modules/nixos/services/networkmanager.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/desktop/cursors.nix
    ../../modules/nixos/desktop/fcitx5.nix
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/desktop/greetd.nix
    ../../modules/nixos/desktop/niri.nix
    ../../modules/nixos/desktop/noctalia.nix
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
