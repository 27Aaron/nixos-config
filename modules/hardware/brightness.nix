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
    # Noctalia 直接寫 /sys/class/backlight/*/brightness,不透過 brightnessctl。
    # 這個套件的 udev 規則把該檔案改成 video 群組可寫;使用者得加入 video。
    # 鍵盤背光的規則則交給 input 群組,這裡不處理。
    services.udev.packages = [ pkgs.brightnessctl ];
    environment.systemPackages = [
      pkgs.brightnessctl
      pkgs.ddcutil
    ];

    user'.extraGroups = [
      "i2c"
      "video"
    ];

    # 外接螢幕走 DDC/CI。Noctalia 預設關閉,裝好後還要在它的設定裡打開
    # brightness.enable_ddcutil,內建面板仍走上面的 backlight。
    hardware.i2c.enable = true;
  };
}
