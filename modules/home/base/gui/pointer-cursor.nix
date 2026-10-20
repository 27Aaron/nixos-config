# 滑鼠指標主題:不是 Cursor 編輯器。
#
# 這個檔案以前叫 desktop/cursor.nix,名字容易讓人以為它管的是 Cursor
# 那個編輯器;它其實只設定 XCursor 主題。容器與鍵盤滑鼠的行為由
# nixos/desktop/niri.nix 決定,這裡不生成那份配置。
{ pkgs, ... }:
{
  # Bibata Modern 的白色;同包另有 Classic(黑色)與 Amber(黃色)。
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
