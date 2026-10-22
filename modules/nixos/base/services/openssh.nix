{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.openssh;
in
{
  options.services'.openssh = {
    enable = lib.mkEnableOption "OpenSSH daemon";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ 233 ];

      # 只產生 Ed25519 主機金鑰,不產生 RSA。
      hostKeys = lib.mkDefault [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      settings = {
        # root 用於遠端部署。
        PermitRootLogin = lib.mkDefault "prohibit-password";
        PasswordAuthentication = lib.mkDefault false;
        # 一併關閉,確保只能以公鑰登入。
        KbdInteractiveAuthentication = lib.mkDefault false;
        PermitEmptyPasswords = lib.mkDefault false;
        # 純 Wayland 主機用不到 X11 轉發。
        X11Forwarding = lib.mkDefault false;
      };
    };

    # 安裝所有 terminfo,各種終端機連入時都能正確顯示。
    environment.enableAllTerminfo = lib.mkDefault true;

    # 只持久化主機金鑰;保留整個 /etc/ssh 會遮住 NixOS 生成的 sshd_config
    # 與 authorized_keys.d(配方取自 preservation 的遷移指南)。
    preservation'.os.files = [
      {
        file = "/etc/ssh/ssh_host_ed25519_key";
        how = "symlink";
        configureParent = true;
      }
    ];
  };
}
