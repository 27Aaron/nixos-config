{
  inputs,
  lib,
  ...
}:
let
  # 客戶端主機別名,來自 nix-secrets。檔案會複製進所有本機帳號都能讀取的
  # /nix/store,只能放別名,不可放金鑰或密碼。
  sshConfig = inputs.secrets + "/openssh/config";
in
{
  # OpenSSH 10 要求 ~/.ssh/config 屬於使用者本人,home.file 的 store 連結
  # 屬於 root,因此改在啟用時複製成一般檔案。
  # 移除條件見 WORKAROUNDS.md 的 WA-006。
  home.activation.installSshConfig = lib.mkIf (builtins.pathExists sshConfig) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install -d -m 700 "$HOME/.ssh"
      rm -f "$HOME/.ssh/config"
      install -m 600 ${sshConfig} "$HOME/.ssh/config"
    ''
  );

  # 客戶端金鑰與 known_hosts。
  persist'.directories = [
    {
      directory = ".ssh";
      mode = "0700";
    }
  ];
}
