{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.services'.openssh;

  # 客戶端主機別名,來自 nix-secrets;不含金鑰。
  sshConfig = inputs.secrets + "/openssh/config";

  # NixOS 模組的 lib 沒有 lib.hm,借用 HM 擴充後的 lib 取得 hm.dag。
  hmLib = import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" lib;
in
{
  options.services'.openssh = {
    enable = lib.mkEnableOption "OpenSSH daemon";
  };

  config = lib.mkMerge [
    (lib.mkIf (builtins.pathExists sshConfig) {
      # OpenSSH 10 要求 ~/.ssh/config 屬於使用者本人,home.file 的 store 連結
      # 屬於 root,因此改在啟用時複製成一般檔案。
      hm'.home.activation.installSshConfig = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
        install -d -m 700 "$HOME/.ssh"
        rm -f "$HOME/.ssh/config"
        install -m 600 ${sshConfig} "$HOME/.ssh/config"
      '';
    })

    (lib.mkIf cfg.enable {
      # 上游 Include 的 systemd ssh proxy 設定在 store 中屬於 nobody,OpenSSH 10
      # 會因擁有者不符而拒絕整份 ssh_config。它只提供本機與 machined 的簡寫。
      programs.ssh.systemd-ssh-proxy.enable = lib.mkDefault false;

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
