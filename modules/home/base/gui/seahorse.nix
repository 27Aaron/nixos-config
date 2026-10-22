{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.seahorse ];

  # GNOME 鑰匙圈資料;seahorse 是其管理介面。
  persist'.directories = [
    {
      directory = ".local/share/keyrings";
      mode = "0700";
    }
  ];
}
