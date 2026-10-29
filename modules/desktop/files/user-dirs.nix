{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop'.user-dirs;
in
{
  options.desktop'.user-dirs.enable = lib.mkEnableOption "XDG user directories";

  config = lib.mkIf cfg.enable {
    hm'.xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME/Desktop";
        documents = "$HOME/Documents";
        download = "$HOME/Downloads";
        music = "$HOME/Music";
        pictures = "$HOME/Pictures";
        videos = "$HOME/Videos";
        publicShare = null;
        templates = null;
      };
      configFile."user-dirs.locale".text = "en_US";
    };

    # x-gvfs-trash 讓檔案總管為這些掛載點啟用回收桶。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable (
      map
        (directory: {
          inherit directory;
          mountOptions = [ "x-gvfs-trash" ];
        })
        [
          "Desktop"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
        ]
    );
  };
}
