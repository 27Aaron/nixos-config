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

    # 跟隨服務的最終狀態(上游可能自行啟用),而非本模組的開關。
    preservation'.os.directories = lib.optionals config.services.upower.enable [
      "/var/lib/upower"
    ];
  };
}
