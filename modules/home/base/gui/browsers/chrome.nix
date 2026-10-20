{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.google-chrome ];

  # Chrome 把使用者資料與可重建的元件混在 profile 根目錄。整包登記可保留
  # Default(書籤、歷史、擴充功能、Cookies、密碼)、Local State 與元件快取,
  # 也讓 Chrome 在目錄內原子替換檔案;根目錄是 tmpfs,元件快取實測可長到
  # 500M 以上。
  persist'.directories = [
    {
      directory = ".config/google-chrome";
      mode = "0700";
    }

    # 快取是為了不佔記憶體才保留:根目錄是 tmpfs,這裡實測可長到 500M 以上。
    {
      directory = ".cache/google-chrome";
      mode = "0700";
    }

    # NSS 共享憑證庫,Chrome 系程式共用;Firefox 不碰這裡。
    # 舊路徑是 .pki,實際 DB 也可能落在 XDG 的 .local/share/pki;兩者都保留。
    # 目前是空的,首次匯入客戶端憑證時才建立;不登記的話私鑰會消失。
    {
      directory = ".pki";
      mode = "0700";
    }
    {
      directory = ".local/share/pki";
      mode = "0700";
    }
  ];
}
