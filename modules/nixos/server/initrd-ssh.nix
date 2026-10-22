{
  config,
  lib,
  ...
}:
let
  cfg = config.server'.initrd-ssh;
in
{
  options.server'.initrd-ssh = {
    enable = lib.mkEnableOption ''
      SSH in initrd for remote LUKS unlock. The host must ensure its NIC
      driver (e.g. r8169, igc, virtio_net) is present in
      boot.initrd.availableKernelModules, or the initrd will have no network.
    '';

    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "SSH port for initrd";
    };

    hostKeys = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.path);
      default = [ "/etc/secrets/initrd/id_ed25519" ];
      description = "Host keys for initrd SSH";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        inherit (cfg) port hostKeys;
      };
    };

    # SSH 登入後直接提示 LUKS 密碼;設在 systemd initrd 的 root 上,
    # 以避開舊選項 boot.initrd.network.ssh.shell 的警告。
    boot.initrd.systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";

    preservation'.os.directories = [ "/etc/secrets/initrd" ];
  };
}
