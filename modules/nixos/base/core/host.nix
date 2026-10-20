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

    # 由 hosts/default.nix 以 specialArgs 傳入,值即 hosts/<名稱> 的目錄名。
    networking.hostName = hostName;

    time.timeZone = lib.mkDefault "Asia/Singapore";

    documentation = {
      man.enable = false;
      nixos.enable = false;
    };
  };
}
