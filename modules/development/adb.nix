{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development'.adb;
in
{
  options.development'.adb.enable = lib.mkEnableOption "Android platform tools";

  config = lib.mkIf cfg.enable {
    hm'.home.packages = [ pkgs.android-tools ];

    # uaccess 只給本機座位上的登入者。SSH 沒有座位,所以 adb 會報 no permissions。
    # 介面類別與 systemd 的 70-uaccess.rules 相同:ADB、fastboot、ADB DbC。
    users.groups.adbusers = { };
    user'.extraGroups = [ "adbusers" ];
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:dc0201:*|*:ff4201:*|*:ff4203:*", MODE="0660", GROUP="adbusers"
    '';

    # 主機金鑰在這裡。根目錄是 tmpfs,不留下的話每次開機都要重新授權。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".android";
        mode = "0700";
      }
    ];
  };
}
