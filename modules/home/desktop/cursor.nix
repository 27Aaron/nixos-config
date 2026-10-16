{ pkgs, ... }:
{
  # Rosé Pine 主色(rose-pine/cursor);同包另有淺色的 BreezeX-RosePineDawn-Linux。
  # niri 的游標由 ~/.config/niri 裡的 cursor 區塊決定,這裡不生成那份配置。
  home.pointerCursor = {
    enable = true;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
    gtk.enable = true;
  };

  # home.pointerCursor 在 ~/.icons 下建立的游標主題連結。
  persist'.directories = [ ".icons" ];
}
