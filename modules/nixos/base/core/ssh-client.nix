{ lib, ... }:
{
  # 上游 Include 的 systemd ssh proxy 設定在 store 中屬於 nobody,OpenSSH 10
  # 會因擁有者不符而拒絕整份 ssh_config,所有 ssh 與 git 操作都會失敗。
  # 它只提供本機與 machined 的簡寫;無論是否啟用 sshd 都要關閉。
  programs.ssh.systemd-ssh-proxy.enable = lib.mkDefault false;
}
