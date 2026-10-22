{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.theme;

  # 另有 latte(淺色)、frappe 與 macchiato。
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
  options.gui'.theme.enable = lib.mkEnableOption "the GTK and Qt theme";

  config = lib.mkIf cfg.enable {
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

    # Kvantum 只掃描設定目錄下的主題子目錄,因此直接連結主題目錄。
    xdg.configFile."Kvantum/catppuccin-${flavor}-${accent}".source =
      "${kvantumTheme}/share/Kvantum/catppuccin-${flavor}-${accent}";

    # 圖示用 Papirus-Dark(nixpkgs 沒有 Catppuccin 圖示)。GTK3 的深色偏好寫在
    # extraConfig;GTK4 不讀這個鍵,深淺色由 Noctalia 決定。
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
        name = "LXGW WenKai TC";
        size = 12;
      };

      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    };

    # GTK 應用與 Nautilus 執行時寫入 dconf 的狀態;未以 dconf.settings 宣告,
    # 無法由設定重建。
    persist'.directories = [
      {
        directory = ".config/dconf";
        mode = "0700";
      }
    ];
  };
}
