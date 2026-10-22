{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.core'.yubikey;
in
{
  options.core'.yubikey = {
    enable = lib.mkEnableOption "YubiKey tools and smart card access";
  };

  config = lib.mkIf cfg.enable {
    programs.yubikey-manager.enable = true;

    # 鑰匙等待觸摸時在圖形工作階段發通知。
    programs.yubikey-touch-detector.enable = true;

    environment.systemPackages = [
      # 提供 fido2-token:查看 FIDO2 憑證、設定 PIN。
      pkgs.libfido2
      # Yubico Authenticator,管理 OATH 驗證碼的圖形介面。
      pkgs.yubioath-flutter
    ];

    # OATH 憑證存於鑰匙本身,這裡只保留應用程式設定。
    preservation'.user.directories = [
      {
        directory = ".local/share/com.yubico.yubioath";
        mode = "0700";
      }
    ];

    # 通用 U2F/FIDO 裝置權限;YubiKey 專用規則由 yubikey-manager 提供。
    services.udev.packages = [ pkgs.libfido2 ];

    # libfido2 的 udev 規則指定 GROUP="plugdev",NixOS 沒有此群組,開機會刷出
    # 上百行解析錯誤。建立空群組即可;實際存取權由規則中的 TAG+="uaccess" 授予。
    users.groups.plugdev = { };
  };
}
