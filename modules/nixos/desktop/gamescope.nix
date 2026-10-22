{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.gamescope;

  # -gamepadui 是 Steam Deck 的大屏介面;-tenfoot 現在也會開大屏,但不是 Deck 版介面。
  steamGamescope = pkgs.writeShellScriptBin "steam-gamescope" ''
    exec ${lib.getExe config.programs.gamescope.package} --steam ${lib.escapeShellArgs cfg.steam.args} -- steam -gamepadui "$@"
  '';
in
{
  options.desktop'.gamescope = {
    enable = lib.mkEnableOption "gamescope, the micro-compositor that renders games at a lower resolution and upscales them";

    steam = {
      enable = lib.mkEnableOption "starting Steam's Big Picture mode inside gamescope from the Steam menu entry";

      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "-w"
          "1440"
          "-h"
          "900"
          "-F"
          "fsr"
        ];
        description = "Arguments passed to gamescope when the Steam menu entry starts it.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.steam.enable -> config.programs.steam.enable;
        message = "desktop'.gamescope.steam.enable requires Steam (desktop'.steam.enable)";
      }
    ];

    # 不開 capSysNice:帶 capability 的 wrapper 在 Steam 的 bubblewrap 容器(no_new_privs)
    # 裡無法啟動,而遊戲正是從那裡呼叫 gamescope。
    programs.gamescope.enable = true;

    # 同名的 steam.desktop 以較高優先權蓋過 Steam 套件內建的選單項目;整個 Steam 跑在
    # gamescope 裡,從它啟動的遊戲都自動套用同一組縮放設定。在 niri 裡開,而不是做成
    # 登入工作階段,關掉 Steam 就回到桌面,不必處理切換工作階段。
    environment.systemPackages = lib.mkIf cfg.steam.enable [
      steamGamescope
      (lib.hiPrio (
        pkgs.makeDesktopItem {
          name = "steam";
          desktopName = "Steam";
          comment = "Steam Big Picture in gamescope";
          exec = "steam-gamescope %U";
          icon = "steam";
          categories = [
            "Network"
            "FileTransfer"
            "Game"
          ];
          mimeTypes = [
            "x-scheme-handler/steam"
            "x-scheme-handler/steamlink"
          ];
        }
      ))
    ];
  };
}
