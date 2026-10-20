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

    # 跟隨服務的最終狀態(上游可能自行啟用),而非本模組的開關。
    preservation'.os.directories = lib.optionals config.services.power-profiles-daemon.enable [
      "/var/lib/power-profiles-daemon"
    ];
  };
}
