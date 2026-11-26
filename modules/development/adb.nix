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
    # programs.adb 已移除。裝置權限由 systemd 的 uaccess 規則處理。
    hm'.home.packages = [ pkgs.android-tools ];

    # 主機金鑰在這裡。根目錄是 tmpfs,不留下的話每次開機都要重新授權。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".android";
        mode = "0700";
      }
    ];
  };
}
