{ config, lib, ... }:
let
  cfg = config.services'.dae;
in
{
  options.services'.dae = {
    enable = lib.mkEnableOption "dae transparent proxy";
  };

  config = lib.mkIf cfg.enable {
    services.dae = {
      enable = true;
      configFile = lib.mkDefault "/etc/dae/config.dae";
    };

    systemd.tmpfiles.rules = [ "d /etc/dae 0700 root root -" ];
    systemd.services = {
      # Credentials are loaded before ExecStartPre, so create the initial
      # config in a separate unit after the persistent directory is mounted.
      dae-initial-config = lib.mkIf (config.services.dae.configFile == "/etc/dae/config.dae") {
        unitConfig.RequiresMountsFor = [ "/etc/dae" ];
        serviceConfig.Type = "oneshot";
        script = ''
          if [ ! -e /etc/dae/config.dae ] && [ ! -L /etc/dae/config.dae ]; then
            mkdir -p -m 0700 /etc/dae
            umask 077
            printf 'global{}\nrouting{}\n' > /etc/dae/config.dae
          fi
        '';
      };

      dae = {
        requires = lib.optional (
          config.services.dae.configFile == "/etc/dae/config.dae"
        ) "dae-initial-config.service";
        after = lib.optional (
          config.services.dae.configFile == "/etc/dae/config.dae"
        ) "dae-initial-config.service";
        unitConfig.RequiresMountsFor = [ "/etc/dae" ];
      };
    };

    preservation'.os.directories = lib.mkIf (config.hardware'.persistence.enable or false) [
      {
        directory = "/etc/dae";
        mode = "0700";
      }
    ];
  };
}
