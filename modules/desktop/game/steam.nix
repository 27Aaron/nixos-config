{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.steam;
in
{
  options.desktop'.steam = {
    enable = lib.mkEnableOption "the Steam client";
  };

  config = lib.mkIf cfg.enable {
    # 上游模組預設不開 Remote Play 與區網傳輸的防火牆埠,維持預設。
    programs.steam = {
      enable = true;

      protontricks.enable = true;

      # Steam 是 X11 程式,在 Wayland 下送出的鍵鼠事件到不了其他視窗;extest 把它們轉成
      # uinput,Steam Input 用手把操作桌面時才有作用。
      extest.enable = true;

      # 取代預設的系統字型(霞鶩文楷),Steam 介面改用文泉驛正黑。
      fontPackages = [ pkgs.wqy_zenhei ];

      # DW-Proton 帶有主線 Proton 與 GE-Proton 沒有的反作弊與遊戲修補,跑鳴潮、
      # 星穹鐵道這類遊戲;GE-Proton 是一般遊戲的備援。在遊戲的「相容性」選用。
      extraCompatPackages = [
        pkgs.dwproton-bin
        pkgs.proton-ge-bin
      ];
    };

    # Steam 本體、登入憑證與 Proton prefix 都在 .local/share/Steam;.steam 是指向它的
    # 連結與 registry.vdf。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".local/share/Steam";
        mode = "0700";
      }
      {
        directory = ".steam";
        mode = "0700";
      }
    ];
  };
}
