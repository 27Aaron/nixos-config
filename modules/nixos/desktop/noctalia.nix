{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop'.noctalia;
in
{
  options.desktop'.noctalia = {
    enable = lib.mkEnableOption "Noctalia desktop shell";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;

      # 掛到圖形工作階段上,登入 niri 後自動啟動。
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };

    # 配置由 Noctalia 自己的介面管理,只保留狀態跨重啟。
    preservation'.user.directories = [
      {
        directory = ".config/noctalia";
        mode = "0700";
      }
      {
        directory = ".local/state/noctalia";
        mode = "0700";
      }
      {
        directory = ".local/share/noctalia";
        mode = "0700";
      }
    ];
  };
}
