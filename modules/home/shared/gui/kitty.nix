{
  config,
  lib,
  ...
}:
let
  cfg = config.gui.kitty;
in
{
  options.gui.kitty.enable = lib.mkEnableOption "the kitty terminal";

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      themeFile = "Catppuccin-Mocha";

      # 字型由 desktop'.fonts 安裝,這裡只指定家族名。
      font = {
        name = "Maple Mono NF";
        size = 12;
      };

      settings = {
        hide_window_decorations = "titlebar-only";
        window_padding_width = "15";

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
