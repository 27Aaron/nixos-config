{
  config,
  lib,
  pkgs,
  username,
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
      description = ''
        Session command Tuigreet launches after login. Null keeps the
        greeter default. Set by the desktop module that owns the session,
        so the greeter binary choice stays inside this module.
      '';
    };

    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to log in to the session command automatically, skipping
        the greeter. Requires sessionCommand; desktop modules forward
        their own autoLogin switch here.
      '';
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

        # The session is started directly on boot; the condition mirrors the
        # assertion above so a missing command fails there instead of here.
        initial_session = lib.mkIf (cfg.autoLogin && cfg.sessionCommand != null) {
          command = cfg.sessionCommand;
          user = username;
        };
      };
    };

    # Tuigreet remembers the last user and session between logins.
    preservation'.os.directories = [
      {
        directory = "/var/cache/tuigreet";
        user = "greeter";
        group = "greeter";
      }
    ];
  };
}
