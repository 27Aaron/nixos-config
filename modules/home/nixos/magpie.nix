# 帶托盤的 GUI 程序。放在 nixos/ 而非 base/gui/,因為它靠 systemd 使用者
# 服務常駐圖形會話,那是 Linux 的啟動方式。
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

  # 托盤程式同時提供本機閘道,關掉視窗也要繼續跑。
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

  # 供應商金鑰與用量在 .config/magpie,WebKit 頁面資料在 .local/share/magpie。
  # 整個 ~/.cache/magpie 一併保留:agents/sessions 是使用者狀態,models.json
  # 與 plugin-*.json 則需要重新下載;目錄 bind mount 也避免原子替換問題。
  # 清理時保留 agents-state.json 與 sessions.json,其餘快取可刪。
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
