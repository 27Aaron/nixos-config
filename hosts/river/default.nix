{
  pkgs,
  vars,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # The root filesystem is volatile; passwords must come from configuration.
  users.mutableUsers = false;

  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.fullName;
    hashedPassword = vars.hashedPassword;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
  };

  # Key-only root login for rescue access.
  users.users.root.openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  #   services.xserver.enable = true;
  #
  #   services.displayManager.gdm.enable = true;
  #   services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  preservation.enable = true;

  preservation.preserveAt."/persistent" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/var/lib/AccountsService"
      "/var/lib/nixos"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };

  system.stateVersion = "26.05";
}
