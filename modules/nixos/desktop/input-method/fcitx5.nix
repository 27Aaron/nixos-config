{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.fcitx5;

  # fcitx5 以 themes/<目錄名>/theme.conf 識別主題,目錄名須與下方 Theme 的值一致。
  mellow-themes = pkgs.fetchFromGitHub {
    owner = "sanweiya";
    repo = "fcitx5-mellow-themes";
    rev = "2c93b0ea3418a55c03f526d963c84a7ccde2c1e9";
    hash = "sha256-y7Q7BgObG99l0+8UVn24TibmUK3Xdq+/1N/G4o9eYAY=";
  };
in
{
  options.desktop'.fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 input method with Rime";
  };

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-gtk
          (fcitx5-rime.override {
            # 方案與詞庫由 rime-ice 提供。
            rimeDataPkgs = [ rime-ice ];
          })
        ];

        settings = {
          inputMethod = {
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "rime";
            };
            "Groups/0/Items/0" = {
              Name = "keyboard-us";
              Layout = "";
            };
            "Groups/0/Items/1" = {
              Name = "rime";
              Layout = "";
            };
            GroupOrder = {
              "0" = "Default";
            };
          };

          # UseDarkTheme:依 xdg-desktop-portal 回報的深淺色切換主題。
          addons.classicui.globalSection = {
            Theme = "mellow-wechat";
            DarkTheme = "mellow-wechat-dark";
            UseDarkTheme = true;
            Font = "LXGW WenKai 12";
            MenuFont = "LXGW WenKai 12";
          };
        };
      };
    };

    # 只連結主題目錄;fcitx5 的使用者資料目錄保持可寫,詞庫才能存下來。
    hm'.xdg.dataFile = {
      "fcitx5/themes/mellow-wechat".source = "${mellow-themes}/mellow-wechat";
      "fcitx5/themes/mellow-wechat-dark".source = "${mellow-themes}/mellow-wechat-dark";
    };

    # 以 rime-ice 取代 fcitx5-rime 的預設方案。
    hm'.xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: rime_ice_suggestion:/
        schema_list:
          - schema: rime_ice
    '';

    preservation'.user.directories = [
      ".config/fcitx5"
      ".local/share/fcitx5"
    ];
  };
}
