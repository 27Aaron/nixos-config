{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.services'.openssh;

  # 客戶端主機別名清單,來自 nix-secrets。不含金鑰,可直接引用。
  sshConfig = inputs.secrets + "/openssh/config";

  # NixOS 模組拿到的 lib 沒有 lib.hm,要引用 HM 啟用腳本的排序庫時,
  # 用 HM 自己的接線把 lib 補齊,再取 hm.dag。
  hmLib = import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" lib;
in
{
  options.services'.openssh = {
    enable = lib.mkEnableOption "OpenSSH daemon";
  };

  config = lib.mkMerge [
    (lib.mkIf (builtins.pathExists sshConfig) {
      # OpenSSH 10 起會檢查 ~/.ssh/config 的最終檔案屬於使用者本人(不看權限
      # 位);home.file 產生的 store 連結屬於 root,通不過檢查,所有 ssh 都會噴
      # Bad owner or permissions。改成啟用時複製成真實檔案,每次切換重寫。
      hm'.home.activation.installSshConfig = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -f "$HOME/.ssh/config"
        install -m 600 ${sshConfig} "$HOME/.ssh/config"
      '';
    })

    (lib.mkIf cfg.enable {
      # 上游預設把 systemd ssh proxy 設定 Include 進 /etc/ssh/ssh_config,但該檔
      # 在 store 裡屬於 nobody。OpenSSH 10 起會檢查被 Include 檔案的擁有者,
      # 不符就中止(Bad owner or permissions on .../20-systemd-ssh-proxy.conf),
      # 整個 ssh_config 失效,所有 ssh 與 git 操作都失敗。該 Include 只提供本機
      # 與 machined 的簡寫,本機沒用到,關掉不影響連線。
      programs.ssh.systemd-ssh-proxy.enable = lib.mkDefault false;

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
          # root 用於遠端部署。
          PermitRootLogin = lib.mkDefault "prohibit-password";
          PasswordAuthentication = lib.mkDefault false;
          # 關掉此通道,publickey 才是唯一方式(舊版 nixpkgs 會在此放行
          # Unix 密碼)。
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitEmptyPasswords = lib.mkDefault false;
          # 純 Wayland 主機用不到 X11 轉發。
          X11Forwarding = lib.mkDefault false;
        };
      };

      # 讓各種終端機經 SSH 連入時都能正確顯示。
      environment.enableAllTerminfo = lib.mkDefault true;

      # 只持久化主機金鑰。持久化整個 /etc/ssh 會在掛載後遮住 NixOS 生成的
      # sshd_config 與 authorized_keys.d,使 sshd 無法認證;配方取自 preservation
      # 的 impermanence 遷移指南。
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
