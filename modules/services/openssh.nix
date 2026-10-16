{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.services'.openssh;

  # 客戶端的主機別名清單,來自 nix-secrets。不含金鑰,可直接引用。
  sshConfig = inputs.secrets + "/openssh/config";
in
{
  options.services'.openssh = {
    enable = lib.mkEnableOption "OpenSSH daemon";
  };

  config = lib.mkMerge [
    (lib.mkIf (builtins.pathExists sshConfig) {
      hm'.home.file.".ssh/config".source = sshConfig;
    })

    (lib.mkIf cfg.enable {
      services.openssh = {
        enable = true;
        ports = [ 233 ];

        # 只需要 Ed25519 主機金鑰;上游預設還會生成 RSA 金鑰。
        hostKeys = lib.mkDefault [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];

        settings = {
          # root 使用者用於遠端部署,因此需要允許
          PermitRootLogin = lib.mkDefault "prohibit-password";
          PasswordAuthentication = lib.mkDefault false;
          # 關閉此通道後,無論 PAM 堆疊為何,publickey 都會是唯一方式
          # (舊版 nixpkgs 會在此放行 Unix 密碼)。
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitEmptyPasswords = lib.mkDefault false;
          # 純 Wayland 主機從 X11 轉發得不到任何好處。
          X11Forwarding = lib.mkDefault false;
        };
      };

      # 把所有已知終端機的 terminfo 資料庫加入系統 profile,讓 SSH 連入的
      # 各種終端機都能正確顯示。
      environment.enableAllTerminfo = lib.mkDefault true;

      # 只持久化主機金鑰本身。持久化整個 /etc/ssh 目錄會在開機掛載後遮住
      # NixOS 生成的 sshd_config 與 authorized_keys.d,使 sshd 無法認證;
      # 配方取自 preservation 的 impermanence 遷移指南。
      preservation'.os.files = [
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          how = "symlink";
          configureParent = true;
        }
      ];

      # 客戶端金鑰與 known_hosts;sshd 也會從這裡讀取 authorized_keys。
      preservation'.user.directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    })
  ];
}
