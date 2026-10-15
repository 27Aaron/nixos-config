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

  # 根檔案系統為揮發性的 tmpfs,密碼必須由配置宣告。
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

  # root 僅允許金鑰登入,供救援使用。
  users.users.root.openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  hardware'.systemd-boot.enable = true;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.persistence.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "26.05";
}
