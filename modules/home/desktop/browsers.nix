{ pkgs, ... }:
{
  home.packages = [
    pkgs.firefox
    pkgs.google-chrome
  ];

  # 設定、書籤與登入態由瀏覽器自行寫入,只保留跨重啟。
  persist'.directories = [
    ".config/mozilla"
    ".mozilla"

    # Chrome 設定檔、擴充功能與瀏覽器狀態。
    {
      directory = ".config/google-chrome";
      mode = "0700";
    }
    # NSS 憑證庫:用戶端憑證與匯入的 CA,私鑰也放在這裡,
    # 其他使用 NSS 的程式共用。
    {
      directory = ".pki";
      mode = "0700";
    }
  ];
}
