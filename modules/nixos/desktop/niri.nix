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

    # 尚未遷移到 Wayland 的應用程式透過 xwayland-satellite 執行,niri 會在需要時自動啟動它。
    environment.systemPackages = [ pkgs.xwayland-satellite ];

    # 檔案選擇對話框沿用預設的 Nautilus(xdg-desktop-portal-gnome)。
    programs.niri.enable = true;

    # 由 greetd 負責登入畫面時,把工作階段回報給它;greeter 的指令組裝與自動登入留在 greetd 模組內。
    desktop'.greetd.sessionCommand = lib.mkIf config.desktop'.greetd.enable niriSession;
    desktop'.greetd.autoLogin = lib.mkIf config.desktop'.greetd.enable cfg.autoLogin;

    # 配置在機器上編輯,暫不由 Nix 生成;只保留目錄跨重啟。
    preservation'.user.directories = [
      ".config/niri"
    ];
  };
}
