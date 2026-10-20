{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.desktop'.greetd;
in
{
  options.desktop'.greetd = {
    enable = lib.mkEnableOption "Greetd login manager with Tuigreet";

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
        default_session.command = lib.mkIf (
          cfg.sessionCommand != null
        ) "${lib.getExe pkgs.tuigreet} --remember --time --cmd ${cfg.sessionCommand}";

        # 條件與上方斷言一致,缺指令時由斷言報錯,不在這裡組出無效設定。
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
