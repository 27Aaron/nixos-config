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
  # 被 Include 的檔案在 store 裡屬於 nobody,OpenSSH 10 因此拒絕整份
  # ssh_config;見 WA-005。它只提供本機與 machined 的簡寫,關掉沒有損失。
  programs.ssh.systemd-ssh-proxy.enable = lib.mkDefault false;

  # OpenSSH 10 要求 ~/.ssh/config 屬於本人,store 連結屬於 root;見 WA-006。
  hm'.home.activation.installSshConfig = lib.mkIf (builtins.pathExists sshConfig) (
    inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install -d -m 700 "$HOME/.ssh"
      rm -f "$HOME/.ssh/config"
      install -m 600 ${sshConfig} "$HOME/.ssh/config"
    ''
  );

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    {
      directory = ".ssh";
      mode = "0700";
    }
  ];
}
