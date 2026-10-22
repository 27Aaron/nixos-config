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

    # 依服務的最終狀態而非本模組開關,上游模組也可能啟用它。
    preservation'.os.directories = lib.optionals config.hardware.bluetooth.enable [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
