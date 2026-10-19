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
