{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.fail2ban;
in
{
  options.services'.fail2ban = {
    enable = lib.mkEnableOption "fail2ban intrusion prevention";
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      # 首次封禁一小時;重複違規則逐次加長,最長一週,並加最多十分鐘的隨機量。
      bantime = "1h";
      # 十分鐘內五次失敗才封禁。密碼登入已關閉,剩下的多是掃金鑰,三次太容易誤傷。
      maxretry = 5;
      bantime-increment = {
        enable = true;
        maxtime = "1w";
        rndtime = "10m";
      };
      jails.DEFAULT.settings.findtime = "10m";
    };

    # 封禁紀錄與計數,跨重啟才不會把累加歸零。
    preservation'.os.directories = [
      "/var/lib/fail2ban"
    ];
  };
}
