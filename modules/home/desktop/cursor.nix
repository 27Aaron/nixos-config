{ pkgs, ... }:
{
  # Bibata Modern 的白色;同包另有 Classic(黑色)與 Amber(黃色)。
  # niri 的游標由 ~/.config/niri 裡的 cursor 區塊決定,這裡不生成那份配置。
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  # home.pointerCursor 在 ~/.icons 下建立的游標主題連結。
  persist'.directories = [ ".icons" ];
}
