# 帶系統匣的 GUI 程式。放在 nixos/ 而非 base/gui/,因為它靠 systemd 使用者
# 服務常駐於圖形工作階段,那是 Linux 的啟動方式。
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  magpie = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.magpie;
in
{
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
  persist' = {
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
}
