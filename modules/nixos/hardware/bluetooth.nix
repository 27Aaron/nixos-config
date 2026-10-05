{ config, lib, ... }:
let
  cfg = config.hardware'.bluetooth;
in
{
  options.hardware'.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
  };

  config = {
    hardware.bluetooth.enable = lib.mkIf cfg.enable true;

    preservation'.os.directories = lib.mkIf (cfg.enable && config.hardware'.persistence.enable) [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
