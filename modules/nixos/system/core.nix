{
  fullName,
  hashedPassword,
  hostName,
  lib,
  sshAuthorizedKeys,
  timeZone,
  username,
  ...
}:
{
  users.mutableUsers = false;

  users.users = {
    root = {
      inherit hashedPassword;
      openssh.authorizedKeys.keys = sshAuthorizedKeys;
    };

    ${username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      inherit hashedPassword;
      description = fullName;
      openssh.authorizedKeys.keys = sshAuthorizedKeys;
    };
  };

  networking.hostName = hostName;
  time.timeZone = lib.mkDefault timeZone;

  documentation = {
    man.cache.enable = false;
    nixos.enable = false;
  };
}
