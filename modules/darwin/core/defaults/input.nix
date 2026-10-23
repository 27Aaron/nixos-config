{
  system.defaults.NSGlobalDomain = {
    "com.apple.swipescrolldirection" = true;
    "com.apple.sound.beep.feedback" = 0; # 調整音量時不發出提示音

    AppleKeyboardUIMode = 2; # 以鍵盤在所有控制項間移動焦點

    # 單位為 15 毫秒;系統設定介面的下限分別是 15 與 2。
    InitialKeyRepeat = 15;
    KeyRepeat = 3;

    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };
}
