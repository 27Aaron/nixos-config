{
  imports = [
    ./hardware.nix
    ./keyboard.nix
    ./power.nix
    ./storage.nix
  ];

  hardware'.yubikey.enable = true;

  desktop' = {
    greetd.enable = true;
    niri.enable = true;
    noctalia.enable = true;
    fonts.enable = true;
    file-manager.enable = true;
    trash.enable = true;
    steam.enable = true;
    gamemode.enable = true;
    pipewire.enable = true;
    fcitx5.enable = true;
    vinput = {
      enable = true;
      lite = true;
    };

    chrome.enable = true;
    firefox.enable = true;
    vscode.enable = true;
    zed.enable = true;
    kitty.enable = true;
    claude-desktop.enable = true;
    dsh-desktop.enable = true;
    nagram.enable = true;
    magpie.enable = true;
    mangohud.enable = true;
    seahorse.enable = true;
    theme.enable = true;
    pointer-cursor.enable = true;
    mime-apps.enable = true;
    user-dirs.enable = true;
  };

  dev' = {
    project-env.enable = true;
    toolchain.enable = true;
    claude-code.enable = true;
    dsh.enable = true;
  };

  services' = {
    avahi.enable = true;
    networkmanager.enable = true;
    openssh.enable = true;
    dae.enable = true;
    logrotate.enable = true;
    podman.enable = true;
    vnstat.enable = true;
  };

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "24.11";
}
