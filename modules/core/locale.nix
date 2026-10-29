{ lib, vars, ... }:
{
  time.timeZone = lib.mkDefault vars.timeZone;

  i18n.defaultLocale = "en_US.UTF-8";
}
