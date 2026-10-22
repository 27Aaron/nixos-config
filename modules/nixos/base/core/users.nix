{ vars, ... }:
{
  # 帳號完全由設定宣告,不接受執行時以 passwd 等指令修改。
  users.mutableUsers = false;

  users.users = {
    # root 的公鑰供遠端部署(services'.openssh.rootLogin)與 initrd 遠端解鎖
    # 使用;其他主機的 sshd 不接受 root 登入。
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
