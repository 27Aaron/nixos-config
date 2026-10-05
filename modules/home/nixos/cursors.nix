{ pkgs, ... }:
{
  # GTK is what applies the cursor theme to GTK applications.
  gtk.enable = true;

  home.pointerCursor = {
    enable = true;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
    gtk.enable = true;
  };

  # Cursor theme links managed by home.pointerCursor under ~/.icons.
  persist'.directories = [ ".icons" ];
}
