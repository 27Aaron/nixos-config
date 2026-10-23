{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop'.power-profiles-daemon;
in
{
  options.desktop'.power-profiles-daemon = {
    enable = lib.mkEnableOption "power-profiles-daemon";
  };

  config = {
    services.power-profiles-daemon.enable = lib.mkIf cfg.enable true;

    # 依服務的最終狀態而非本模組開關,上游模組也可能啟用它。
    preservation'.os.directories =
      lib.mkIf (config.hardware'.persistence.enable && config.services.power-profiles-daemon.enable)
        [
          "/var/lib/power-profiles-daemon"
        ];
  };
}
