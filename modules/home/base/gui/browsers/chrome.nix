{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.google-chrome ];

  # 整個 profile 保留:Chrome 把使用者資料與可重建元件混放,
  # 且會在目錄內以原子替換方式寫檔。
  persist'.directories = [
    {
      directory = ".config/google-chrome";
      mode = "0700";
    }

    # 快取放在持久卷以免佔用 tmpfs(可達 500M 以上)。
    {
      directory = ".cache/google-chrome";
      mode = "0700";
    }

    # NSS 共用憑證庫(Chrome 系程式使用),新舊路徑都保留,匯入的客戶端
    # 憑證才不會遺失。
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
