{
  username = "aaron";
  fullName = "Aaron";
  email = "85681241+27Aaron@users.noreply.github.com";

  # 由 mkpasswd -m yescrypt 生成。
  # TODO: 哈希目前公開提交在倉庫中;待接入私有 secrets 倉庫後,
  # 改用 hashedPasswordFile 指向 /persistent 下的文件並從此處移除。
  hashedPassword = "$y$j9T$ssZgTIeq9iObnQ5SWCLoN0$rVag2jJiBbEOgeYcphtYPZ5pbTvpF1ukKcdMBkDK0z0";

  appearance = import ./appearance.nix;

  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6xNNhF6jaPKuch8vSHwHTGlbyn4i2zSHxrqGOiacxG Aaron@Deployment"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHjMAQUXfyMv8TG1NfqjmQJG3gqZkh25KAvAMvxVrWS Aaron@MacBook-Pro"
  ];
}
