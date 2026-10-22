{
  xdg = {
    enable = true;

    # Public 與 Templates 用不到,設成 null 就不建立。
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
  persist'.directories =
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
      ];
}
