{
  username = "aaron";
  fullName = "Aaron";
  email = "niceboy@duck.com";
  timeZone = "Asia/Singapore";

  # mkpasswd -m yescrypt
  hashedPassword = "$y$j9T$ssZgTIeq9iObnQ5SWCLoN0$rVag2jJiBbEOgeYcphtYPZ5pbTvpF1ukKcdMBkDK0z0";

  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6xNNhF6jaPKuch8vSHwHTGlbyn4i2zSHxrqGOiacxG Aaron@Deployment"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHjMAQUXfyMv8TG1NfqjmQJG3gqZkh25KAvAMvxVrWS Aaron@MacBook-Pro"
  ];
}
