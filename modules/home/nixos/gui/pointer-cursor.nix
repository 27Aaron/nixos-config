{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.pointer-cursor;
in
{
  options.gui.pointer-cursor.enable = lib.mkEnableOption "the pointer cursor theme";

  config = lib.mkIf cfg.enable {
    # Bibata Modern Ice 為白色款,同套件另有 Classic(黑)與 Amber(黃)。
    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
      gtk.enable = true;
    };

    # home.pointerCursor 在 ~/.icons 建立的連結。
    persist.directories = lib.mkIf config.persist.enable [ ".icons" ];
  };
}
