{
  # GTK 應用程式直接讀這兩個檔,不經過 dconf,Noctalia 也不會寫它們。
  # 系統的 color-scheme 偏好則由 Noctalia 在套用主題時自行設定。
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };
}
