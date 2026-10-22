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

    # GameMode 的 polkit 規則只讓 gamemode 群組免密碼以 root 執行 CPU 調速器等輔助程式,
    # 不在群組裡大多數調整都不會生效。見 WORKAROUNDS.md 的 WA-021。
    user'.extraGroups = [ "gamemode" ];
  };
}
