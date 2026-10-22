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
    enable = lib.mkEnableOption "the niri Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    # niri 會在 X11 應用程式需要時自動啟動 xwayland-satellite。
    environment.systemPackages = [ pkgs.xwayland-satellite ];

    programs.niri.enable = true;

    desktop'.greetd.sessionCommand = lib.mkIf config.desktop'.greetd.enable niriSession;

    # 設定直接在機器上編輯,不由 Nix 生成。
    preservation'.user.directories = [
      ".config/niri"
    ];
  };
}
