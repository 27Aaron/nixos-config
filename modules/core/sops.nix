{
  config,
  inputs,
  pkgs,
  vars,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 使用者密碼靠它解密(見 users.nix),所以一律啟用。金鑰必須是沒有密碼的
  # ed25519:啟用時沒有人能輸入。換金鑰前先讀 SECURITY.md;風險見 WA-016。
  #
  # 讀持久化磁碟上的那份:開機解密時 ~/.ssh 的 bind mount 可能還沒掛上。
  sops.age.sshKeyPaths = [
    "/persistent${config.users.users.${vars.username}.home}/.ssh/id_ed25519"
  ];

  environment.systemPackages = [
    pkgs.sops
    pkgs.ssh-to-age
  ];
}
