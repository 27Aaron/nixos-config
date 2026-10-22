{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.brightness;
in
{
  options.hardware'.brightness = {
    enable = lib.mkEnableOption "display brightness control";
  };

  config = lib.mkIf cfg.enable {
    # Noctalia 直接寫入 /sys/class/backlight;brightnessctl 的 udev 規則讓
    # video 群組可寫。
    services.udev.packages = [ pkgs.brightnessctl ];
    environment.systemPackages = [
      pkgs.brightnessctl
      pkgs.ddcutil
    ];

    user'.extraGroups = [
      "i2c"
      "video"
    ];

    # 外接螢幕經 DDC/CI 調整,需在 Noctalia 設定中開啟 enable_ddcutil。
    hardware.i2c.enable = true;
  };
}
