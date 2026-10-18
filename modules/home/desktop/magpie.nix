{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  magpie = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.magpie-desktop;
in
{
  # 桌面包同時提供 magpie 命令。終端包也叫 magpie,不要再裝一份。
  home.packages = [ magpie ];

  # 套件自帶 magpie:// 處理器。上游在 Linux 上不再往家目錄寫桌面檔。
  xdg.mimeApps.defaultApplications."x-scheme-handler/magpie" = [ "magpie.desktop" ];

  # 托盤程序同時提供本機閘道。登入圖形工作階段後啟動,關掉視窗也不該停。
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

  # 供應商金鑰、用量與 WebKit 的頁面資料都要跨重啟。快取在已保留的 .cache 裡。
  persist'.directories = [
    {
      directory = ".config/magpie";
      mode = "0700";
    }
    {
      directory = ".local/share/magpie";
      mode = "0700";
    }
  ];
}
