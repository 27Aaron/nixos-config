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

    # 主機名稱來自 hosts/<名稱> 目錄名,由 hosts/default.nix 以 specialArgs 傳入。
    networking.hostName = hostName;

    # 各設備在自身配置中覆寫此預設時區。
    time.timeZone = lib.mkDefault "Asia/Singapore";

    # 把所有已知終端機的 terminfo 資料庫加入系統 profile。
    environment.enableAllTerminfo = lib.mkDefault true;

    documentation = {
      man.enable = false;
      nixos.enable = false;
    };
  };
}
