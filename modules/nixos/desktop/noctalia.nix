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

      # 遊戲模式(gamescope-session)也會帶起 graphical-session.target,
      # 綁在 niri 上 Noctalia 才不會在沒有 layer-shell 的 gamescope 裡反覆崩潰。
      systemd = {
        enable = true;
        target = "niri.service";
      };
    };

    # 設定由 Noctalia 介面管理,不由 Nix 生成。
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
