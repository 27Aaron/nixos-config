{
  lib,
  username,
  timeZone,
  hostName,
  ...
}:
{
  programs.fish.enable = lib.mkDefault true;

  time.timeZone = lib.mkDefault timeZone;

  system.primaryUser = username;

  users.users.${username}.home = "/Users/${username}";

  networking = {
    hostName = hostName;
    computerName = hostName;
  };
  system.defaults.smb.NetBIOSName = hostName;
}
