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
    # ykman,以及 CCID 讀卡機 pcscd 與 YubiKey 的 udev 規則。
    programs.yubikey-manager.enable = true;

    # 圖形工作階段中,鑰匙等待觸摸時發通知。
    programs.yubikey-touch-detector.enable = true;

    environment.systemPackages = [
      # fido2-token:查看 FIDO2 憑證、設定 PIN。
      pkgs.libfido2

      # Yubico Authenticator:圖形介面管理 OATH 驗證碼。
      pkgs.yubioath-flutter
    ];

    # 驗證碼存在鑰匙上;這裡只留應用程式自己的設定。
    preservation'.user.directories = [
      {
        directory = ".local/share/com.yubico.yubioath";
        mode = "0700";
      }
    ];

    # 通用 U2F/FIDO 權限。YubiKey 專用規則已由 yubikey-manager 帶入。
    services.udev.packages = [ pkgs.libfido2 ];

    # libfido2 帶入的 70-u2f.rules 每條都寫了 GROUP="plugdev",但 NixOS 沒有
    # 這個組(Debian 系才有),udev 因此對每一條規則各報一次
    # "Failed to resolve group 'plugdev'"。開機時會累積上百行,把真正的錯誤淹掉。
    #
    # 這裡建一個沒有成員的空組,只為了讓規則解析通過。存取權仍由同一條規則裡的
    # TAG+="uaccess" 決定(systemd-logind 對當前登入者授予 ACL),
    # 不依賴組成員身分,所以不必把使用者加進去。
    users.groups.plugdev = { };
  };
}
