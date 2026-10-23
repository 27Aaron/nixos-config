{
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    # 螢幕保護程式或睡眠後立即要求密碼。
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising = false;
  };
}
