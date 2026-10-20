{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.smartd;
in
{
  options.services'.smartd = {
    enable = lib.mkEnableOption "SMART and NVMe health monitoring";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dmidecode
      lm_sensors
      smartmontools
      usbutils
    ];

    services.smartd = {
      enable = true;
      autodetect = true;
      extraOptions = [
        "--interval=21600"
        "--savestates=/var/lib/smartmontools/smartd."
      ];
      notifications.systembus-notify.enable = true;
    };

    systemd.services.smartd.serviceConfig = {
      StateDirectory = "smartmontools";
      StateDirectoryMode = "0750";
    };

    preservation'.os.directories = [
      {
        directory = "/var/lib/smartmontools";
        mode = "0750";
      }
    ];
  };
}
