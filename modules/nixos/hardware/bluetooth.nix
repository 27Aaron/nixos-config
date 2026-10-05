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

    # Pairings live on the ephemeral root, so keep them whenever Bluetooth is
    # enabled, regardless of which module turned it on.
    preservation'.os.directories =
      lib.optionals (config.hardware'.persistence.enable && config.hardware.bluetooth.enable)
        [
          {
            directory = "/var/lib/bluetooth";
            mode = "0700";
          }
        ];
  };
}
