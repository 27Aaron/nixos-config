{ pkgs, ... }:
{
  # sops-nix 本體與解密金鑰路徑由 nixos/ 設定。解密金鑰是使用者
  # 自己的 SSH 金鑰,不另外保存金鑰檔;它必須是 ed25519 且沒有密碼,因為啟用時
  # 沒有人能輸入。明確指定也取代了上游的預設值(sshd 主機金鑰)。
  # 換金鑰前要先用其他收件人換鎖,見 SECURITY.md;已接受的風險見 WA-016。
  environment.systemPackages = [
    pkgs.sops
    pkgs.ssh-to-age
  ];
}
