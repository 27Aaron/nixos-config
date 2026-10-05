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

    # XWayland support for applications that have not moved to Wayland yet.
    environment.systemPackages = [ pkgs.xwayland-satellite ];

    programs.niri.enable = true;

    # Report the session to greetd when it drives the login screen; the
    # greeter command and autologin assembly stay inside the greetd module.
    desktop'.greetd.sessionCommand = lib.mkIf config.desktop'.greetd.enable niriSession;
    desktop'.greetd.autoLogin = lib.mkIf config.desktop'.greetd.enable cfg.autoLogin;

    # Niri's configuration is edited on the host, so keep it across reboots.
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".config/niri"
    ];
  };
}
