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
    enable = lib.mkEnableOption "the Rosé Pine cursor theme";
  };

  config = lib.mkIf cfg.enable {
    # GTK is what applies the cursor theme to GTK applications, so this module
    # turns it on rather than depending on a separate theme module.
    hm'.gtk.enable = true;

    hm'.home.pointerCursor = {
      enable = true;
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      size = 24;
      gtk.enable = true;
    };

    # Cursor theme links managed by home.pointerCursor under ~/.icons.
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".icons"
    ];
  };
}
