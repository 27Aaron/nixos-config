{ lib, ... }:
{
  # 被 Include 的檔案在 store 裡屬於 nobody,OpenSSH 10 因此拒絕整份
  # ssh_config;見 WA-005。它只提供本機與 machined 的簡寫,關掉沒有損失。
  programs.ssh.systemd-ssh-proxy.enable = lib.mkDefault false;
}
