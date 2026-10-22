# 使用者帳號。帳號完全由設定宣告,不接受執行時以 passwd 等指令修改。
{ vars, ... }:
{
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
}
