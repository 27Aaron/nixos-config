{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.google-chrome ];

  # Chrome 把使用者資料與可重建的元件混在 profile 根目錄,因此不能整包照收。
  # 這裡只登記真正會丟失登入態的部分;其餘(元件快取、模型、GPU 快取)
  # 都留在 tmpfs 上,重新聯網後 Chrome 會自己補回。
  persist'.directories = [
    # 使用者設定檔:書籤、歷史、擴充功能、IndexedDB、Local Storage、
    # Cookies、已儲存的密碼與各項偏好。整個 Default 目錄即為使用者資料。
    {
      directory = ".config/google-chrome/Default";
      mode = "0700";
    }

    # HTTP 快取。保留是為了不佔用記憶體:根目錄是 4G 的 tmpfs,
    # 而 Chrome 的快取實測可長到 500M 以上。
    {
      directory = ".cache/google-chrome";
      mode = "0700";
    }

    # NSS 共享憑證庫:用戶端憑證與匯入的 CA,私鑰也放在這裡。
    # Chrome 系的程式(含 p11-kit、certutil 等)共用這一份。
    # Firefox 不碰這裡,它用自己 profile 內的 cert9.db 與 key4.db。
    #
    # 目前目錄是空的:Chrome 首次匯入客戶端憑證時才會建立 nssdb。
    # 不登記的話,重開機後匯入的憑證與其私鑰會消失。
    {
      directory = ".pki";
      mode = "0700";
    }
  ];
}
