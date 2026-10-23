_: {
  # macOS 的 wheel 只有 root,管理者帳號在 admin 群組;root 一律可連線。
  daemon-access =
    { config, ... }:
    {
      expr = config.nix.settings.allowed-users;
      expected = [ "@admin" ];
    };
}
