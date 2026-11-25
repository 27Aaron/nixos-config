{
  config,
  inputs,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.development'.dsh;

  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;

  # dsh rejects wildcard addresses, so --host always names one concrete local IP.
  webOnLan =
    !(builtins.elem cfg.web.bind [
      "127.0.0.1"
      "::1"
    ]);
in
{
  options.development'.dsh = {
    enable = lib.mkEnableOption "the DeepSeek dsh agent";

    web = {
      enable = lib.mkEnableOption "the dsh web GUI as a systemd user service";

      bind = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        example = "10.10.10.254";
        description = ''
          Address for `dsh --profile web --host`. dsh accepts one concrete local
          IP and rejects wildcards. A non-loopback address is served over plain
          HTTP, and the startup token is its only gate, so the network it is
          reachable from has to be trusted.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3080;
        description = "Port for `dsh --profile web --port`.";
      };

      trustedHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "selene.local" ];
        description = ''
          Extra authorities for `dsh --profile web --trusted-host`, one flag per
          entry. The Host/Origin fence accepts the bind address itself; browsing
          by hostname requires naming that hostname here.
        '';
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.web.enable || cfg.enable;
          message = "development'.dsh.web runs the dsh package; enable development'.dsh too.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      hm'.home.packages = [ dsh ];

      preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
        {
          directory = ".dsh";
          mode = "0700";
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.web.enable) {
      # Lingering starts the user service at boot with nobody logged in.
      users.users.${vars.username}.linger = lib.mkDefault true;

      hm'.systemd.user.services.dsh-web = {
        Unit = {
          Description = "dsh web GUI";
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = lib.escapeShellArgs (
            [
              (lib.getExe dsh)
              "--profile"
              "web"
              "--no-open"
              "--host"
              cfg.web.bind
              "--port"
              (toString cfg.web.port)
            ]
            ++ lib.concatMap (host: [
              "--trusted-host"
              host
            ]) cfg.web.trustedHosts
          );
          WorkingDirectory = "%h";
          Restart = "on-failure";
          RestartSec = 5;
          # Every start mints a new login token and prints it on the `dsh web:`
          # line; the service has no terminal, so read it with
          # `journalctl --user -u dsh-web -o cat`. API keys live in
          # ~/.dsh/.credentials.yaml and persist with .dsh, never in this
          # configuration.
        };

        Install.WantedBy = [ "default.target" ];
      };

      networking.firewall.allowedTCPPorts = lib.optional webOnLan cfg.web.port;

      boot.kernel.sysctl = lib.mkIf (webOnLan && cfg.web.port < 1024) {
        "net.ipv4.ip_unprivileged_port_start" = cfg.web.port;
      };
    })
  ];
}
