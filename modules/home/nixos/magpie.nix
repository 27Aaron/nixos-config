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

  # 供應商金鑰與用量在 .config/magpie,WebKit 的頁面資料在
  # .local/share/magpie。~/.cache 不再整體持久化,因此 magpie 放在那裡的
  # 使用者狀態要逐項登記;其餘(bun、update、models.json、plugin-*.json 等)
  # 都是可重新下載的內容,留在 tmpfs 上即可。
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
      # 開啟過的檔案與工作階段索引;它指向 .dsh 的 session 檔,
      # 對應的內容本身已持久化。
      {
        file = ".cache/magpie/sessions.json";
        mode = "0600";
      }
    ];
  };
}
