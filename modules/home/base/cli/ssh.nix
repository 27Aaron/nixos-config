{
  config,
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
  # OpenSSH 10 要求 ~/.ssh/config 屬於本人,store 連結屬於 root;見 WA-006。
  home.activation.installSshConfig = lib.mkIf (builtins.pathExists sshConfig) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install -d -m 700 "$HOME/.ssh"
      rm -f "$HOME/.ssh/config"
      install -m 600 ${sshConfig} "$HOME/.ssh/config"
    ''
  );

  persist.directories = lib.mkIf config.persist.enable [
    {
      directory = ".ssh";
      mode = "0700";
    }
  ];
}
