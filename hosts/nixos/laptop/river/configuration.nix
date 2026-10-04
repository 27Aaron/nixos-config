{
  hashedPassword,
  nixosHardware,
  pkgs,
  username,
  ...
}:
{
  imports = [
    nixosHardware.nixosModules.apple-t2
    ../../../../modules/nixos/hardware/disko.nix
    ../../../../modules/nixos/hardware/persistence.nix
    ../../../../modules/nixos/hardware/boot/grub.nix
    ../../../../modules/nixos/hardware/boot/systemd-boot.nix
    ../../../../modules/nixos/hardware/bluetooth.nix
    ../../../../modules/nixos/services/openssh.nix
    ../../../../modules/nixos/services/networkmanager.nix
    ./hardware.nix
    ./storage.nix
  ];

  hardware'.systemd-boot.enable = true;
  hardware'.bluetooth.enable = true;
  services'.openssh.enable = true;
  services'.networkmanager.enable = true;

  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.initrd.systemd.enable = true;

  networking = {
    hostName = "river";
    firewall.allowedTCPPorts = [ 22 ];
  };

  services.openssh.settings = {
    PasswordAuthentication = true;
    KbdInteractiveAuthentication = true;
    PermitRootLogin = "no";
  };

  time.timeZone = "Asia/Shanghai";
  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    inherit hashedPassword;
  };

  hardware.apple-t2.firmware = {
    enable = true;
    version = "sonoma";
  };

  preservation.preserveAt."/persistent".directories = [
    "/etc/nixos"
    "/var/lib/AccountsService"
    {
      directory = "/home/${username}";
      user = username;
      group = "users";
      mode = "0700";
    }
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "26.11";
}
