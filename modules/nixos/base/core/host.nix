{
  lib,
  hostName,
  vars,
  ...
}:
{
  config = {
    users.mutableUsers = false;

    users.users = {
      root = {
        hashedPassword = vars.hashedPassword;
        openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
      };

      ${vars.username} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPassword = vars.hashedPassword;
        openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
      };
    };

    # hostName 即 hosts/ 下的目錄名,由 hosts/default.nix 傳入。
    networking.hostName = hostName;

    time.timeZone = lib.mkDefault "Asia/Singapore";

    documentation = {
      man.enable = false;
      nixos.enable = false;
    };
  };
}
