{
  imports = [
    ./hardware.nix
    ./power.nix
    ./storage.nix
  ];

  time.timeZone = "Asia/Tokyo";

  desktop' = {
    greetd.enable = true;
    niri.enable = true;
    noctalia.enable = true;

    fonts.enable = true;
    theme.enable = true;
    pointer-cursor.enable = true;

    file-manager.enable = true;
    trash.enable = true;
    mime-apps.enable = true;
    user-dirs.enable = true;

    chrome.enable = true;
    firefox.enable = true;

    zed.enable = true;
    vscode.enable = true;

    fcitx5.enable = true;

    pipewire.enable = true;
    kitty.enable = true;
    seahorse.enable = true;
    "1password".enable = true;
  };

  development' = {
    project-env.enable = true;
    toolchain.enable = true;
    adb.enable = true;
    claude-code.enable = true;

    dsh.enable = true;
    dsh.web = {
      enable = true;
      bind = "10.10.10.20";
      trustedHosts = [ "selene.local" ];
    };
  };

  services' = {
    avahi.enable = true;
    magpie.enable = true;
    networkmanager.enable = true;
    openssh.enable = true;
    openssh.rootLogin = true;
    vnstat.enable = true;
  };

  system.stateVersion = "23.05";
}
