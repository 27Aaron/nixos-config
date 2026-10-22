# 字型與主題的唯一定義來源,系統模組與 Home Manager 模組都從 vars.appearance 讀取。
{
  fonts = {
    # 介面字型以繁體字形為主,簡體字形作為後備。
    sans = "LXGW WenKai TC";
    sansSimplified = "LXGW WenKai";
    mono = "Maple Mono NF";
    emoji = "Noto Color Emoji";
  };

  # Catppuccin 風味:latte(淺色)、frappe、macchiato、mocha(深色)。
  catppuccin = {
    dark = "mocha";
    light = "latte";
    accent = "mauve";
  };
}
