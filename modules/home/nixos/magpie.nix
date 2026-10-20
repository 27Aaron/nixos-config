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
  # ~/.cache 不整體持久化,所以放在那裡的使用者狀態要逐項登記;其餘(bun、
  # models.json、plugin-*.json)可重新下載,留在 tmpfs 即可。
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
    ];

    files = [
      # 自訂的 agent 定義(模型、選項、路徑),重建不會還原。
      {
        file = ".cache/magpie/agents-state.json";
        mode = "0600";
      }
      # 開啟過的檔案與工作階段索引,指向 .dsh 的 session 檔。
      {
        file = ".cache/magpie/sessions.json";
        mode = "0600";
      }
    ];
  };
}
