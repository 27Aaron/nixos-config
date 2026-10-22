{
  username = "aaron";
  fullName = "Aaron";
  email = "85681241+27Aaron@users.noreply.github.com";

  # 由 mkpasswd -m yescrypt 生成。
  # TODO: 雜湊公開在倉庫與其 Git 歷史中,可被離線暴力破解。改存到私有的
  # nix-secrets,以 sops 的 neededForUsers 解密後交給 hashedPasswordFile,
  # 再從這裡移除;舊雜湊已外流,搬移時一併更換密碼。
  hashedPassword = "$y$j9T$ssZgTIeq9iObnQ5SWCLoN0$rVag2jJiBbEOgeYcphtYPZ5pbTvpF1ukKcdMBkDK0z0";

  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6xNNhF6jaPKuch8vSHwHTGlbyn4i2zSHxrqGOiacxG Aaron@Deployment"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHjMAQUXfyMv8TG1NfqjmQJG3gqZkh25KAvAMvxVrWS Aaron@MacBook-Pro"
  ];
}
