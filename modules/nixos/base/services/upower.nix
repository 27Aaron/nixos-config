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

    # 依服務的最終狀態而非本模組開關,上游模組也可能啟用它。
    preservation'.os.directories = lib.optionals config.services.upower.enable [
      "/var/lib/upower"
    ];
  };
}
