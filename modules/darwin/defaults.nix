# macOS 系统默认值。
# 选项：https://daiderd.com/nix-darwin/manual/index.html#sec-options
# defaults 键名参考：https://github.com/yannbertrand/macos-defaults
{ username, ... }:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    menuExtraClock.Show24Hour = true;
    menuExtraClock.ShowSeconds = true;

    dock = {
      autohide = true;
      show-recents = false;
      wvous-tl-corner = 2; # 调度中心
      wvous-tr-corner = 4; # 桌面
      wvous-bl-corner = 3; # 应用窗口
      wvous-br-corner = 13; # 锁定屏幕
    };

    finder = {
      _FXShowPosixPathInTitle = true; # 标题栏显示完整路径
      _FXSortFoldersFirst = true; # 文件夹排在文件前
      AppleShowAllExtensions = true; # 显示所有扩展名
      FXDefaultSearchScope = "SCcf"; # 默认搜索当前文件夹
      FXEnableExtensionChangeWarning = false; # 改扩展名不弹警告
      NewWindowTarget = "Home"; # 新窗口打开主目录
      QuitMenuItem = true; # 显示“退出”
      ShowPathbar = true; # 显示路径栏
      ShowStatusBar = true; # 显示状态栏
      ShowExternalHardDrivesOnDesktop = true; # 桌面显示外接硬盘
      ShowHardDrivesOnDesktop = false; # 桌面不显示内置硬盘
      ShowMountedServersOnDesktop = true; # 桌面显示已挂载服务器
      ShowRemovableMediaOnDesktop = true; # 桌面显示可移动介质
    };

    spaces.spans-displays = false; # 每个显示器各自独立的空间

    WindowManager = {
      EnableStandardClickToShowDesktop = false; # 点击壁纸不显示桌面
      StandardHideDesktopIcons = false; # 桌面显示图标
      HideDesktop = false; # 台前调度中不隐藏项目
      StageManagerHideWidgets = false; # 台前调度中显示小组件
      StandardHideWidgets = false; # 桌面上显示小组件
    };

    screensaver = {
      askForPassword = true; # 屏保或睡眠后立即要求密码
      askForPasswordDelay = 0;
    };

    screencapture = {
      location = "/Users/${username}/Desktop";
      type = "png";
    };

    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = true; # 自然滚动
      "com.apple.sound.beep.feedback" = 0; # 关闭音量变化提示音

      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 2;

      InitialKeyRepeat = 15; # 长按开始重复的延迟，越小越快
      KeyRepeat = 3; # 按键重复速度，越小越快

      # 关闭智能替换与自动纠正
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };

    CustomUserPreferences = {
      ".GlobalPreferences" = {
        AppleSpacesSwitchOnActivate = true; # 切换应用时跳到它所在的空间
      };
      NSGlobalDomain = {
        WebKitDeveloperExtras = true; # 网页右键菜单显示“检查元素”
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true; # 网络卷不生成 .DS_Store
        DSDontWriteUSBStores = true; # USB 卷不生成 .DS_Store
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false; # 关闭个性化广告
      };
      "com.apple.ImageCapture".disableHotPlug = true; # 插入设备不自动打开“照片”
    };
  };
}
