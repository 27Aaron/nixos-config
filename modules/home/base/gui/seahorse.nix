{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.seahorse ];

  # GNOME 鑰匙環,seahorse 就是它的管理介面。
  persist'.directories = [
    {
      directory = ".local/share/keyrings";
      mode = "0700";
    }
  ];
}
