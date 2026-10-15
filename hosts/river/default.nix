{
  pkgs,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  time.timeZone = "Asia/Tokyo";

  core'.firewall.enable = true;

  hardware'.systemd-boot.enable = true;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.persistence.enable = true;

  services'.openssh.enable = true;
  services'.networkmanager.enable = true;
  services'.pipewire.enable = true;
  services'.power-profiles-daemon.enable = true;
  services'.upower.enable = true;
  services'.zram.enable = true;
  services'.btrfs-scrub.enable = true;
  services'.smartd.enable = true;
  services'.btrbk.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "26.05";
}
