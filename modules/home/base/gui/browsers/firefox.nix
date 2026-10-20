{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.firefox ];

  # 使用者資料在 .config/mozilla,快取在 .cache/mozilla,兩者分得很乾淨。
  #
  # profile 整個保留:storage/ 佔了一半以上,但那是各網站的登入態而非快取,
  # 丟掉等同全部登出;資料庫彼此關聯,逐項拆容易漏。
  #
  # 憑證不需要另外登記,Firefox 用 profile 內的 cert9.db/key4.db。
  persist'.directories = [
    ".config/mozilla"

    # 快取是為了不佔記憶體才保留:根目錄是 tmpfs,這裡實測可長到 1G 以上。
    {
      directory = ".cache/mozilla";
      mode = "0700";
    }
  ];
}
