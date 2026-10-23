{
  system.defaults = {
    finder = {
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      AppleShowAllExtensions = true;
      FXDefaultSearchScope = "SCcf"; # 搜尋預設只找目前資料夾
      FXEnableExtensionChangeWarning = false;
      NewWindowTarget = "Home";
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
    };

    # 儲存對話框預設展開,直接顯示路徑選擇。
    NSGlobalDomain = {
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };

    CustomUserPreferences = {
      # 不在網路磁碟與 USB 磁碟上產生 .DS_Store。
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # 接上裝置時不自動開啟「照片」。
      "com.apple.ImageCapture".disableHotPlug = true;
    };
  };
}
