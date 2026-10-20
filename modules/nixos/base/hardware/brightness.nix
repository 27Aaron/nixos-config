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
    # Noctalia 直接寫 /sys/class/backlight/*/brightness。這個套件的 udev 規則
    # 把該檔案改成 video 群組可寫,所以使用者要加入 video。
    services.udev.packages = [ pkgs.brightnessctl ];
    environment.systemPackages = [
      pkgs.brightnessctl
      pkgs.ddcutil
    ];

    user'.extraGroups = [
      "i2c"
      "video"
    ];

    # 外接螢幕走 DDC/CI;Noctalia 的 brightness.enable_ddcutil 預設關閉,
    # 要在它的設定裡打開才會生效。
    hardware.i2c.enable = true;
  };
}
