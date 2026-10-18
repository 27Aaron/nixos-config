{ pkgs, ... }:
let
  # 最深的 Mocha,強調色 Mauve。Latte 是淺色,Frappé 與 Macchiato 介於兩者之間。
  flavor = "mocha";
  accent = "mauve";

  gtkTheme = pkgs.catppuccin-gtk.override {
    variant = flavor;
    accents = [ accent ];
  };

  kvantumTheme = pkgs.catppuccin-kvantum.override {
    variant = flavor;
    inherit accent;
  };
in
{
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "kvantum";

    # 目錄名由打包腳本決定:themes/catppuccin-<風味>-<強調色>。
    kvantum = {
      enable = true;
      settings.General.theme = "catppuccin-${flavor}-${accent}";
    };
  };

  # catppuccin-kvantum 裝在 share/Kvantum,Kvantum 只掃描其子目錄,
  # 所以把主題目錄本身連結進去。
  xdg.configFile."Kvantum/catppuccin-${flavor}-${accent}".source =
    "${kvantumTheme}/share/Kvantum/catppuccin-${flavor}-${accent}";

  # nixpkgs 沒有 Catppuccin 圖示主題,圖示用 Papirus 的深色版。
  # GTK3 直接讀 extraConfig,不經過 dconf。GTK4 不用這個鍵,深色由 Noctalia 的 color-scheme 設定。
  gtk = {
    enable = true;

    theme = {
      package = gtkTheme;
      name = "catppuccin-${flavor}-${accent}-standard";
    };

    gtk4.theme = {
      package = gtkTheme;
      name = "catppuccin-${flavor}-${accent}-standard";
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    font = {
      name = "Source Han Sans TC";
      size = 12;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };
}
