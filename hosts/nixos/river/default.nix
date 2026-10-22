{ ... }:

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
    niri = {
      enable = true;
      autoLogin = true;
    };
    noctalia.enable = true;
    fonts.enable = true;
    file-manager.enable = true;
    trash.enable = true;
    pipewire.enable = true;
    fcitx5.enable = true;
    vinput = {
      enable = true;
      lite = true;
    };
  };

  services' = {
    networkmanager.enable = true;
    openssh.enable = true;
    sops.enable = true;
    dae.enable = true;
    logrotate.enable = true;
    vnstat.enable = true;
  };

  hm' = {
    cli' = {
      development.enable = true;
      git.enable = true;
      packages.enable = true;
      shell.enable = true;
      ssh.enable = true;
      toolchain.enable = true;
    };

    tui' = {
      claude-code.enable = true;
      dsh.enable = true;
      lazygit.enable = true;
      monitoring.enable = true;
    };

    gui' = {
      chrome.enable = true;
      firefox.enable = true;
      vscode.enable = true;
      zed.enable = true;
      kitty.enable = true;
      claude-desktop.enable = true;
      dsh-desktop.enable = true;
      nagram.enable = true;
      magpie.enable = true;
      seahorse.enable = true;
      theme.enable = true;
      pointer-cursor.enable = true;
      mime-apps.enable = true;
      user-dirs.enable = true;
    };
  };

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "24.11";
}
