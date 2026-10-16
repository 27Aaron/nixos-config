{

  # prefer-dark 會經由 xdg-desktop-portal 廣播給會跟隨系統外觀的程式,
  # 例如 fcitx5 的深淺色主題切換。
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # GTK 應用程式直接讀這兩個檔,不經過 dconf。
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };
}
