{
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha";

    font = {
      name = "Maple Mono NF";
      size = 14;
    };

    settings = {
      # Window appearance.
      hide_window_decorations = "titlebar-only";
      window_padding_width = "15";
      background_opacity = "0.85";
      background_blur = "30";
      remember_window_size = "yes";
      enable_audio_bell = false;

      # Tabs and cursor.
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      cursor_blink_interval = "0";
      mouse_hide_wait = "1";
    };
  };
}
