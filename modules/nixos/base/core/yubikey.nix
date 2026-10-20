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

    # OATH 驗證碼存在鑰匙上,這裡只留應用程式設定。
    preservation'.user.directories = [
      {
        directory = ".local/share/com.yubico.yubioath";
        mode = "0700";
      }
    ];

    # 通用 U2F/FIDO 權限。YubiKey 專用規則已由 yubikey-manager 帶入。
    services.udev.packages = [ pkgs.libfido2 ];

    # libfido2 的 70-u2f.rules 每條都寫 GROUP="plugdev",但 NixOS 沒有這個組
    # (Debian 系才有),udev 逐條報 "Failed to resolve group 'plugdev'",開機
    # 累積上百行把真正的錯誤淹掉。空組只為了讓規則解析通過:存取權由同一條
    # 規則的 TAG+="uaccess" 決定(systemd-logind 授予登入者 ACL),不看組成員。
    users.groups.plugdev = { };
  };
}
