{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop'.gamemode;
in
{
  options.desktop'.gamemode = {
    enable = lib.mkEnableOption "Feral GameMode";
  };

  config = lib.mkIf cfg.enable {
    programs.gamemode = {
      enable = true;
      # 預設 renice 為 0,等於不調整遊戲的優先權。
      settings.general.renice = 10;
    };

    # GameMode 的 polkit 規則只讓這個群組執行調整輔助程式;見 WA-021。
    user'.extraGroups = [ "gamemode" ];
  };
}
