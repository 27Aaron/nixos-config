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

    # 跟隨服務的最終狀態(上游可能自行啟用),而非本模組的開關。
    preservation'.os.directories = lib.optionals config.hardware.bluetooth.enable [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
