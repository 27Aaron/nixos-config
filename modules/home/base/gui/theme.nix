{ pkgs, ... }:
let
  # Latte 是淺色,Frappé 與 Macchiato 介於兩者之間。
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

  # Kvantum 只掃描 share/Kvantum 的子目錄,所以把主題目錄本身連結進去。
  xdg.configFile."Kvantum/catppuccin-${flavor}-${accent}".source =
    "${kvantumTheme}/share/Kvantum/catppuccin-${flavor}-${accent}";

  # nixpkgs 沒有 Catppuccin 圖示主題,用 Papirus 深色版代替。
  # GTK3 直接讀 extraConfig;GTK4 不用這個鍵,深色由 Noctalia 決定。
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

  # dconf 存放 GTK 應用與 Nautilus 執行時寫入的外觀狀態(游標、視窗大小)。
  # 本倉庫沒有宣告 dconf.settings,這些內容無法由 rebuild 重建,不登記就會
  # 每次開機從零開始。
  persist'.directories = [
    {
      directory = ".config/dconf";
      mode = "0700";
    }
  ];
}
