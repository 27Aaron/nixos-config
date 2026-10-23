{
  config,
  inputs,
  vars,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 每臺主機的使用者密碼都由 sops 解密(見 users.nix),因此一律啟用。
  #
  # 直接讀持久化磁碟上的那份:開機解密時 ~/.ssh 的 bind mount 可能還沒掛上。
  sops.age.sshKeyPaths = [
    "/persistent${config.users.users.${vars.username}.home}/.ssh/id_ed25519"
  ];
}
