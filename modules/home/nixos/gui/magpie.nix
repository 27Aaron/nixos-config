{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.magpie;

  magpie = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.magpie;
in
{
  options.gui'.magpie.enable = lib.mkEnableOption "magpie and its tray service";

  config = lib.mkIf cfg.enable {
    home.packages = [ magpie ];

    xdg.mimeApps.defaultApplicationPackages = [ magpie ];

    # 系統匣程式同時提供本機閘道,關掉視窗也要繼續跑。
    systemd.user.services.magpie = {
      Unit = {
        Description = "magpie menu bar and local model gateway";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe magpie} tray";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };

    # 金鑰與用量在 .config/magpie,WebKit 資料在 .local/share/magpie;
    # ~/.cache/magpie 含 agents/sessions 狀態,清理時保留 agents-state.json
    # 與 sessions.json 即可。
    persist' = lib.mkIf config.persist'.enable {
      directories = [
        {
          directory = ".config/magpie";
          mode = "0700";
        }
        {
          directory = ".local/share/magpie";
          mode = "0700";
        }
        {
          directory = ".cache/magpie";
          mode = "0700";
        }
      ];
    };
  };
}
