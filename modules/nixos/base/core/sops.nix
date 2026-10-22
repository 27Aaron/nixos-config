{
  config,
  pkgs,
  vars,
  ...
}:
{
  # 每臺主機的使用者密碼都由 sops 解密(見 users.nix),因此一律啟用。
  #
  # 解密金鑰是使用者自己的 SSH 金鑰,不另外保存金鑰檔;它必須是 ed25519 且沒有
  # 密碼,因為開機時沒有人能輸入。直接讀持久化磁碟上的那份:開機解密時 ~/.ssh
  # 的 bind mount 可能還沒掛上。明確指定也取代了上游的預設值(sshd 主機金鑰)。
  # 換金鑰前要先用其他收件人換鎖,見 SECURITY.md;已接受的風險見 WA-016。
  sops.age.sshKeyPaths = [
    "/persistent${config.users.users.${vars.username}.home}/.ssh/id_ed25519"
  ];

  environment.systemPackages = [
    pkgs.sops
    pkgs.ssh-to-age
  ];
}
