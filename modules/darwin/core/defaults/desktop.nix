{
  system.defaults = {
    NSGlobalDomain.AppleInterfaceStyle = "Dark";

    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
    };

    spaces.spans-displays = false; # 每個顯示器各自擁有獨立空間

    WindowManager = {
      EnableStandardClickToShowDesktop = false; # 點擊桌布不顯示桌面
      StandardHideDesktopIcons = false;
      HideDesktop = false;
      StageManagerHideWidgets = false;
      StandardHideWidgets = false;
    };

    CustomUserPreferences = {
      # 切換應用程式時自動跳到它所在的空間。
      ".GlobalPreferences".AppleSpacesSwitchOnActivate = true;
      # 網頁檢視的右鍵選單加上「檢閱元素」。
      NSGlobalDomain.WebKitDeveloperExtras = true;
    };
  };
}
