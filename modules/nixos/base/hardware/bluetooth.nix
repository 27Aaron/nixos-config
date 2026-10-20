{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.bluetooth;
in
{
  options.hardware'.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
  };

  config = {
    hardware.bluetooth.enable = lib.mkIf cfg.enable true;

    # 上游消費者可能自行啟用此服務,持久化跟隨服務的最終狀態,
    # 無論是誰開啟的。
    preservation'.os.directories = lib.optionals config.hardware.bluetooth.enable [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
