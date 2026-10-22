{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.desktop'.greetd;
  # tuigreet 預設只找 /usr/share/wayland-sessions,NixOS 沒有這個目錄。
  sessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
in
{
  options.desktop'.greetd = {
    enable = lib.mkEnableOption "the greetd login manager with tuigreet";

    sessionCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "niri-session";
      description = "Command Tuigreet runs after login. Null uses the greeter default.";
    };

    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Log in without the greeter. Requires sessionCommand.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.autoLogin || cfg.sessionCommand != null;
        message = "desktop'.greetd.autoLogin requires desktop'.greetd.sessionCommand to be set";
      }
    ];

    services.greetd = {
      enable = true;
      useTextGreeter = true;
      settings = {
        default_session.command =
          lib.mkIf (cfg.sessionCommand != null)
            "${lib.getExe pkgs.tuigreet} --remember --time --sessions ${sessions} --cmd ${cfg.sessionCommand}";

        # 缺少 sessionCommand 時交由上方斷言報錯。
        initial_session = lib.mkIf (cfg.autoLogin && cfg.sessionCommand != null) {
          command = cfg.sessionCommand;
          user = vars.username;
        };
      };
    };

    # tuigreet 以 --remember 記住上次的使用者與工作階段。
    preservation'.os.directories = [
      {
        directory = "/var/cache/tuigreet";
        user = "greeter";
        group = "greeter";
      }
    ];
  };
}
