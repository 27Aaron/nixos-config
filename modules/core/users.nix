{
  config,
  inputs,
  vars,
  ...
}:
let
  # 雜湊以 sops 加密存在 nix-secrets,在建立帳號前解密到 /run/secrets-for-users,
  # 不經過所有人可讀的 /nix/store。解密失敗時帳號會被鎖住、無法 sudo,
  # 從開機選單選上一代即可復原。
  hashedPasswordFile = config.sops.secrets.hashedPassword.path;
in
{
  sops.secrets.hashedPassword = {
    sopsFile = "${inputs.secrets}/users/password.yaml";
    neededForUsers = true;
  };

  users.mutableUsers = false;

  users.users = {
    # root 的公鑰供遠端部署(services'.openssh.rootLogin)與 initrd 遠端解鎖
    # 使用;其他主機的 sshd 不接受 root 登入。
    root = {
      inherit hashedPasswordFile;
      openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
    };

    ${vars.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      inherit hashedPasswordFile;
      openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
    };
  };
}
