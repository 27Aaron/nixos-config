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

      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };

    # 設定由 Noctalia 介面管理,只保留狀態跨重啟。
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
      {
        directory = ".cache/noctalia";
        mode = "0700";
      }
    ];
  };
}
