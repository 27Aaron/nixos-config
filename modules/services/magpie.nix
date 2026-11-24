{
  config,
  inputs,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.services'.magpie;
  webOnLan =
    cfg.web.enable
    && !(builtins.elem cfg.web.bind [
      "localhost"
      "127.0.0.1"
      "::1"
    ]);
in
{
  # 桌面托盤版在 desktop'.magpie;這裡是無螢幕主機上以使用者服務常駐的
  # 閘道與網頁介面,同一個主機不要同時開啟兩者。
  options.services'.magpie = {
    enable = lib.mkEnableOption "the magpie gateway as a systemd user service";

    package =
      lib.mkPackageOption inputs.magpie.packages.${pkgs.stdenv.hostPlatform.system} "magpie-cli"
        { };

    address = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "127.0.0.1:3425";
      description = ''
        MAGPIE_ADDR. Null leaves the gateway on the address saved in its
        settings, which is 127.0.0.1:3425 until changed.
      '';
    };

    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://10.10.10.254:3430";
      description = ''
        MAGPIE_PUBLIC_URL: the address other machines use to reach the
        gateway.
      '';
    };

    web = {
      enable = lib.mkEnableOption "the browser UI from the same process (`magpie serve --web`)";

      bind = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        example = "10.10.10.254";
        description = "Address passed to `magpie serve --web`.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3430;
        description = "Port passed to `magpie serve --web`.";
      };

      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          MAGPIE_WEB_KEY. Null lets magpie mint a new key on every start,
          which signs browsers out. At least 16 characters from
          [A-Za-z0-9._~-].
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.desktop'.magpie.enable;
        message = "services'.magpie and desktop'.magpie both run magpie; enable one of them.";
      }
      {
        assertion = cfg.address == null || lib.hasInfix ":" cfg.address;
        message = "services'.magpie.address must be host:port.";
      }
      {
        assertion = cfg.web.key == null || (builtins.stringLength cfg.web.key >= 16);
        message = "services'.magpie.web.key must be at least 16 characters.";
      }
    ];

    hm'.home.packages = [ cfg.package ];

    # 使用者服務要在沒有人登入時於開機就啟動。
    users.users.${vars.username}.linger = lib.mkDefault true;

    sops.secrets."magpie/env" = {
      sopsFile = inputs.secrets + "/services/magpie.env";
      format = "dotenv";
      owner = config.users.users.${vars.username}.name;
      mode = "0400";
      restartUnits = [ "magpie-user-restart.service" ];
    };

    systemd.services.magpie-user-restart = {
      description = "Restart the magpie user service after its env file changes";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user -M ${vars.username}@ restart magpie.service";
      };
    };

    hm'.systemd.user.services.magpie = {
      Unit = {
        Description = "magpie gateway";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = lib.concatStringsSep " " (
          [
            (lib.getExe cfg.package)
            "serve"
          ]
          ++ lib.optional cfg.web.enable "--web=${cfg.web.bind}:${toString cfg.web.port}"
        );
        Restart = "on-failure";
        RestartSec = 5;
        EnvironmentFile = [ config.sops.secrets."magpie/env".path ];
        Environment =
          lib.optional (cfg.address != null) "MAGPIE_ADDR=${cfg.address}"
          ++ lib.optional (cfg.publicUrl != null) "MAGPIE_PUBLIC_URL=${cfg.publicUrl}"
          ++ lib.optional (cfg.web.enable && cfg.web.key != null) "MAGPIE_WEB_KEY=${cfg.web.key}";
      };

      Install.WantedBy = [ "default.target" ];
    };

    networking.firewall.allowedTCPPorts = lib.optional webOnLan cfg.web.port;

    boot.kernel.sysctl = lib.mkIf (webOnLan && cfg.web.port < 1024) {
      "net.ipv4.ip_unprivileged_port_start" = cfg.web.port;
    };

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".config/magpie";
        mode = "0700";
      }
      {
        directory = ".cache/magpie";
        mode = "0700";
      }
      {
        directory = ".local/state/magpie";
        mode = "0700";
      }
    ];
  };
}
