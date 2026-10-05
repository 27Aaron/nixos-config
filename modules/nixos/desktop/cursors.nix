{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.cursors;
in
{
  options.desktop'.cursors = {
    enable = lib.mkEnableOption "Bibata cursor theme";
  };

  config = lib.mkIf cfg.enable {
    # GTK is what applies the cursor theme to GTK applications, so this module
    # turns it on rather than depending on a separate theme module.
    hm'.gtk.enable = true;

    hm'.home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
    };

    # Cursor theme links managed by home.pointerCursor under ~/.icons.
    preservation'.user.directories = [
      ".icons"
    ];
  };
}
