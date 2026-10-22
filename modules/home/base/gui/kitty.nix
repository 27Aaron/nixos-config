{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.gui'.kitty;
  inherit (vars.appearance) catppuccin fonts;
in
{
  options.gui'.kitty.enable = lib.mkEnableOption "the kitty terminal";

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      # 另有 Frappe、Macchiato 與淺色的 Latte。
      themeFile = "Catppuccin-${lib.toSentenceCase catppuccin.dark}";

      # 字型由 desktop'.fonts 安裝,這裡只指定家族名。
      font = {
        name = fonts.mono;
        size = 12;
      };

      settings = {
        # 只隱藏標題列,視窗邊框與陰影保留。
        hide_window_decorations = "titlebar-only";
        window_padding_width = "15";

        # 背景模糊需要合成器支援。
        background_opacity = "0.85";
        background_blur = "30";

        remember_window_size = "yes";
        enable_audio_bell = false;

        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        cursor_blink_interval = "0";
        mouse_hide_wait = "1";
      };
    };
  };
}
