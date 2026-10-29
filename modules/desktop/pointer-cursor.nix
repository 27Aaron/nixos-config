{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.pointer-cursor;
in
{
  options.desktop'.pointer-cursor.enable = lib.mkEnableOption "the pointer cursor theme";

  config = lib.mkIf cfg.enable {
    hm'.home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
      gtk.enable = true;
    };

    # home.pointerCursor 在 ~/.icons 建立的連結。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [ ".icons" ];
  };
}
