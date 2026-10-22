{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.firefox ];

  # profile 整個保留:storage/ 存放網站登入狀態,各資料庫彼此關聯,不宜拆開。
  # 憑證位於 profile 內的 cert9.db/key4.db,無需另外登記。
  persist'.directories = [
    ".config/mozilla"

    # 快取放在持久卷以免佔用 tmpfs(可達 1G 以上)。
    {
      directory = ".cache/mozilla";
      mode = "0700";
    }
  ];
}
