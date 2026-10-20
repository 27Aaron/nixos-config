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

    # tmpfs 根之下要登記才跨重啟:Nautilus 的星號、圖示位置等檔案中繼資料。
    #
    # 刻意不持久化 ~/.local/share/Trash。trash 規格要求「被丟棄檔案的
    # topdir 必須等於回收桶的 topdir」,而家目錄的 topdir 是根 tmpfs;
    # 回收桶一旦 bind 掛載到持久卷就成了另一個 topdir,結果是家目錄第一層
    # 的檔案完全無法丟回收桶(Nautilus、gio trash、rm --trash 皆然):
    #   Unable to trash file ... across filesystem boundaries
    # 家目錄回收桶留在 tmpfs 上,重開機即清空,符合這個系統的語意。
    # 掛載點底下的檔案(如 Downloads)進到該掛載點內的 .Trash-$uid,
    # 隨目錄本身保留,由 services'.trash 的保留計時器清理。
    preservation'.user.directories = [
      {
        directory = ".local/share/gvfs-metadata";
        mode = "0700";
      }
      # Nautilus 的星號與標籤資料庫(meta.db),同樣是執行時寫入的
      # 二進位檔,rebuild 不會重建。
      {
        directory = ".local/share/nautilus";
        mode = "0700";
      }
    ];
  };
}
