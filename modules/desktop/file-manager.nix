{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.file-manager;
in
{
  options.desktop'.file-manager = {
    enable = lib.mkEnableOption "Nautilus file manager with GVfs trash support";
  };

  config = lib.mkIf cfg.enable {
    # 檔案總管本體。mime-apps 的 inode/directory 預設與
    # xdg-desktop-portal-gnome 的檔案選擇對話框都指向 Nautilus,
    # 但 programs.niri 只把它註冊成 D-Bus 服務,必須另外裝進系統,
    # .desktop 檔才進得了 XDG_DATA_DIRS。
    environment.systemPackages = [
      pkgs.nautilus

      # gio 工具:檔案總管沒開著時,也能從終端丟回收桶、清空回收桶。
      pkgs.glib.bin
    ];

    # GVfs 提供回收桶(trash:///)與卸除式裝置、網路位置等支援;
    # user-dirs 的各掛載點已帶 x-gvfs-trash,gvfs 會把回收桶匯總成同一個檢視。
    services.gvfs.enable = true;

    # tmpfs 根之下要登記才跨重啟:回收桶內容,以及 Nautilus 的
    # 星號、圖示位置等檔案中繼資料。
    # 家目錄掛載點上的檔案(如 Downloads)丟進掛載點內的 .Trash-$uid,
    # 隨目錄本身保留;這裡保留的是 tmpfs 家目錄區域的回收桶。
    preservation'.user.directories = [
      ".local/share/Trash"
      {
        directory = ".local/share/gvfs-metadata";
        mode = "0700";
      }
    ];
  };
}
