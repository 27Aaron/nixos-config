{ lib, ... }:
{
  # 主機可在自己的 default.nix 覆寫時區。
  time.timeZone = lib.mkDefault "Asia/Singapore";

  i18n.defaultLocale = "en_US.UTF-8";
}
