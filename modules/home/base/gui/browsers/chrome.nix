{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.google-chrome ];

  # Chrome 把使用者資料與可重建的元件混在 profile 根目錄,不能整包照收。
  # 只登記會丟失登入態的部分,元件快取與模型留在 tmpfs 上,聯網後會補回。
  persist'.directories = [
    # 整個 Default 目錄即使用者資料:書籤、歷史、擴充功能、Cookies、密碼。
    {
      directory = ".config/google-chrome/Default";
      mode = "0700";
    }

    # 快取是為了不佔記憶體才保留:根目錄是 tmpfs,這裡實測可長到 500M 以上。
    {
      directory = ".cache/google-chrome";
      mode = "0700";
    }

    # NSS 共享憑證庫,Chrome 系程式共用;Firefox 不碰這裡。
    # 目前是空的,首次匯入客戶端憑證時才建立;不登記的話私鑰會消失。
    {
      directory = ".pki";
      mode = "0700";
    }
  ];
}
