{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.yubikey;
in
{
  options.hardware'.yubikey = {
    enable = lib.mkEnableOption "YubiKey tools and smart card access";
  };

  config = lib.mkIf cfg.enable {
    programs.yubikey-manager.enable = true;

    programs.yubikey-touch-detector.enable = true;

    environment.systemPackages = [
      # 提供 fido2-token:查看 FIDO2 憑證、設定 PIN。
      pkgs.libfido2
      pkgs.yubioath-flutter
    ];

    # OATH 憑證存於鑰匙本身,這裡只保留應用程式設定。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".local/share/com.yubico.yubioath";
        mode = "0700";
      }
    ];

    # 通用 U2F/FIDO 裝置權限;YubiKey 專用規則由 yubikey-manager 提供。
    services.udev.packages = [ pkgs.libfido2 ];

    # libfido2 的 udev 規則指定 GROUP="plugdev",存取權實際由 uaccess 授予;
    # 見 WA-011。
    users.groups.plugdev = { };
  };
}
