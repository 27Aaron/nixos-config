{
  # 只有 admin 能連上 nix-daemon;macOS 的 wheel 只有 root,一般管理者帳號在
  # admin 群組。root 一律可連線。
  nix.settings.allowed-users = [ "@admin" ];
}
