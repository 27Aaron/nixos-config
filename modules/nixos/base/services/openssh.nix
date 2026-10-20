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
      # OpenSSH 10 起,讀取 ~/.ssh/config 前會檢查最終檔案屬於使用者本人
      # (權限位不檢查);home.file 產生的 store 符號連結(root 所有)通不過
      # 檢查,所有 ssh 指令都會噴 Bad owner or permissions。因此改在啟用時
      # 複製成使用者自己的真實檔案,每次切換都重寫,內容仍以 nix-secrets 為源。
      hm'.home.activation.installSshConfig = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -f "$HOME/.ssh/config"
        install -m 600 ${sshConfig} "$HOME/.ssh/config"
      '';
    })

    (lib.mkIf cfg.enable {
      # 上游預設把 systemd 的 ssh proxy 設定 Include 進 /etc/ssh/ssh_config,
      # 但那個檔案在 Nix store 裡屬於 nobody。OpenSSH 10 起會檢查被 Include
      # 檔案的擁有者,不符就中止並印出
      #   Bad owner or permissions on .../20-systemd-ssh-proxy.conf
      # 結果是整個 /etc/ssh/ssh_config 失效,所有 ssh 與 git 操作都會失敗。
      #
      # 這裡關掉該 Include。它只提供 .host / unix/* / machine/* 這類連到
      # 本機與 machined 虛擬機的簡寫,本機沒有用到(ssh-unix-local socket
      # 不存在),關閉不影響任何既有連線。
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
