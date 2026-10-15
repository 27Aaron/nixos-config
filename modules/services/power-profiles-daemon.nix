{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.power-profiles-daemon;
in
{
  options.services'.power-profiles-daemon = {
    enable = lib.mkEnableOption "Power profiles management daemon";
  };

  config = {
    services.power-profiles-daemon.enable = lib.mkIf cfg.enable true;

    # 上游消費者可能自行啟用此守護程式,持久化跟隨服務的最終狀態,
    # 無論是誰開啟的。
    preservation'.os.directories = lib.optionals config.services.power-profiles-daemon.enable [
      "/var/lib/power-profiles-daemon"
    ];
  };
}
