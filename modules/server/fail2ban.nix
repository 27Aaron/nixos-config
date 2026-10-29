{
  config,
  lib,
  ...
}:
let
  cfg = config.server'.fail2ban;
in
{
  options.server'.fail2ban = {
    enable = lib.mkEnableOption "fail2ban intrusion prevention";
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      bantime = "1h";
      # 十分鐘內失敗五次才封禁;密碼登入已關閉,放寬次數以免誤封。
      maxretry = 5;
      bantime-increment = {
        enable = true;
        maxtime = "1w";
        rndtime = "10m";
      };
      jails.DEFAULT.settings.findtime = "10m";
    };

    # 保留封禁紀錄,遞增的封禁時間才不會在重開機後歸零。
    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      "/var/lib/fail2ban"
    ];
  };
}
