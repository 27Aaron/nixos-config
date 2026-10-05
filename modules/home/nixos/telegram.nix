{ pkgs, ... }:
{
  home.packages = [ pkgs.telegram-desktop ];

  # Telegram Desktop session data and settings, including tdata.
  persist'.directories = [ ".local/share/TelegramDesktop" ];
}
