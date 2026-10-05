{
  lib,
  pkgs,
  username,
  timeZone,
  hostName,
  ...
}:
{
  programs.fish.enable = lib.mkDefault true;

  time.timeZone = lib.mkDefault timeZone;

  system.primaryUser = username;

  users.users.${username} = {
    home = "/Users/${username}";
    shell = lib.mkDefault pkgs.fish;
  };

  networking = {
    hostName = hostName;
    computerName = hostName;
  };
  system.defaults.smb.NetBIOSName = hostName;
}
