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
    # programs.niri 只註冊 Nautilus 的 D-Bus 服務;須裝進系統,.desktop 檔
    # 才會出現在 XDG_DATA_DIRS,供 mime-apps 與 portal 使用。
    environment.systemPackages = [
      pkgs.nautilus

      # 提供 gio,可從終端機把檔案移到回收桶。
      pkgs.glib.bin
    ];

    # GVfs 提供回收桶(trash:///)與卸除式裝置;user-dirs 的掛載點已帶 x-gvfs-trash。
    services.gvfs.enable = true;

    # 刻意不持久化 ~/.local/share/Trash:回收桶須與檔案位於同一檔案系統,
    # bind 到持久卷後,家目錄第一層的檔案就無法丟進回收桶。持久化目錄內的
    # 檔案會進各自的 .Trash-$uid,由 desktop'.trash 定期清理。
    preservation'.user.directories = [
      # 執行時產生的中繼資料,無法由設定重建。
      {
        directory = ".local/share/gvfs-metadata";
        mode = "0700";
      }
      {
        directory = ".local/share/nautilus";
        mode = "0700";
      }

      # 縮圖可能洩漏私人檔案內容,限本人讀取;保留可免去重新產生。
      {
        directory = ".cache/thumbnails";
        mode = "0700";
      }
    ];
  };
}
