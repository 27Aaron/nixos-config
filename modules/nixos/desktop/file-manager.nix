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
    # mime-apps 與 xdg-desktop-portal-gnome 都指向 Nautilus,但 programs.niri
    # 只註冊 D-Bus 服務,必須裝進系統,.desktop 檔才進得了 XDG_DATA_DIRS。
    environment.systemPackages = [
      pkgs.nautilus

      # 提供 gio 指令,檔案總管沒開著時也能從終端丟回收桶。
      pkgs.glib.bin
    ];

    # GVfs 提供回收桶(trash:///)與卸除式裝置;user-dirs 的掛載點已帶 x-gvfs-trash。
    services.gvfs.enable = true;

    # 刻意不持久化 ~/.local/share/Trash:trash 規格要求被丟棄檔案的 topdir
    # 等於回收桶的 topdir,家目錄的 topdir 是根 tmpfs;回收桶一旦 bind 到
    # 持久卷就成了另一個 topdir,家目錄第一層的檔案便無法丟回收桶
    # (Nautilus、gio trash 皆然):Unable to trash file ... across filesystem
    # boundaries。掛載點底下的檔案改進該掛載點的 .Trash-$uid,隨目錄保留,
    # 由 services'.trash 定期清理。
    preservation'.user.directories = [
      # 以下都是執行時寫入的二進位檔,rebuild 不會重建。
      {
        directory = ".local/share/gvfs-metadata";
        mode = "0700";
      }
      {
        directory = ".local/share/nautilus";
        mode = "0700";
      }
    ];
  };
}
