{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.upower;
in
{
  options.services'.upower = {
    enable = lib.mkEnableOption "UPower power management daemon";
  };

  config = {
    services.upower.enable = lib.mkIf cfg.enable true;

    # 上游消費者可能自行啟用此守護程式,持久化跟隨服務的最終狀態,
    # 無論是誰開啟的。
    preservation'.os.directories = lib.optionals config.services.upower.enable [
      "/var/lib/upower"
    ];
  };
}
