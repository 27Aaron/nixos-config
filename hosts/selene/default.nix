{
  imports = [
    ./hardware.nix
    ./power.nix
    ./storage.nix
  ];

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

    fcitx5.enable = true;

    magpie.enable = true;

    pipewire.enable = true;
    kitty.enable = true;
    seahorse.enable = true;
    "1password".enable = true;
  };

  development' = {
    project-env.enable = true;
    toolchain.enable = true;
    claude-code.enable = true;
  };

  services' = {
    avahi.enable = true;
    networkmanager.enable = true;
    openssh.enable = true;
    openssh.rootLogin = true;
    vnstat.enable = true;
  };

  system.stateVersion = "23.05";
}
