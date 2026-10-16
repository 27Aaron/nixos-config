{
  programs.kitty = {
    enable = true;

    # Rosé Pine 主色;另有 rose-pine-moon 與 rose-pine-dawn。
    themeFile = "rose-pine";

    # 字型由 desktop'.fonts 安裝,這裡只指定家族名。
    font = {
      name = "Maple Mono NF";
      size = 14;
    };

    settings = {
      # 只隱藏標題列,視窗邊框與陰影保留。
      hide_window_decorations = "titlebar-only";
      # 視窗內容與邊框之間的留白,單位像素。
      window_padding_width = "15";
      # 背景透明度與背後模糊;模糊需要合成器支援。
      background_opacity = "0.85";
      background_blur = "30";
      # 記住上次手動調整的視窗大小。
      remember_window_size = "yes";
      # 響鈴不發聲。
      enable_audio_bell = false;

      # 分頁列放在視窗上方,用斜角 powerline 樣式分隔分頁。
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      # 游標不閃爍。
      cursor_blink_interval = "0";
      # 滑鼠靜止 1 秒後隱藏。
      mouse_hide_wait = "1";
    };
  };
}
