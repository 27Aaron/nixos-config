# 滑鼠指標主題,不是 Cursor 編輯器;檔案原名 desktop/cursor.nix 容易誤會。
# 視窗內的游標由 niri 決定,這裡只設 XCursor。
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

  # home.pointerCursor 在 ~/.icons 建立的連結。
  persist'.directories = [ ".icons" ];
}
