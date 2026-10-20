{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.niri;
  niriSession = lib.getExe' pkgs.niri "niri-session";
in
{
  options.desktop'.niri = {
    enable = lib.mkEnableOption "Niri desktop environment";

    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to log in to the Niri session automatically";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.autoLogin || config.desktop'.greetd.enable;
        message = "desktop'.niri.autoLogin requires desktop'.greetd.enable, which drives the login screen";
      }
    ];

    # 未遷移到 Wayland 的應用程式由 niri 按需要自動啟動 xwayland-satellite。
    environment.systemPackages = [ pkgs.xwayland-satellite ];

    programs.niri.enable = true;

    desktop'.greetd.sessionCommand = lib.mkIf config.desktop'.greetd.enable niriSession;
    desktop'.greetd.autoLogin = lib.mkIf config.desktop'.greetd.enable cfg.autoLogin;

    # 設定在機器上編輯,不由 Nix 生成;只保留目錄跨重啟。
    preservation'.user.directories = [
      ".config/niri"
    ];
  };
}
