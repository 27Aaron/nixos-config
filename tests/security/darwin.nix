{ ... }:
let
  vars = import ../../vars;
in
{
  # macOS 的 wheel 只有 root,管理者帳號在 admin 群組;root 一律可連線。
  daemon-access =
    { config, ... }:
    {
      expr = config.nix.settings.allowed-users;
      expected = [ "@admin" ];
    };

  # sops 只用使用者自己的 SSH 金鑰解密,不再有共用或自動產生的金鑰檔。
  sops-key =
    { config, ... }:
    {
      expr = {
        inherit (config.sops.age) keyFile sshKeyPaths generateKey;
      };
      expected = {
        keyFile = null;
        sshKeyPaths = [ "/Users/${vars.username}/.ssh/id_ed25519" ];
        generateKey = false;
      };
    };
}
