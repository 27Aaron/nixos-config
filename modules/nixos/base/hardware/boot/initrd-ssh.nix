{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.initrd-ssh;
in
{
  options.hardware'.initrd-ssh = {
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

    # SSH 會話中用 systemd-tty-ask-password-agent 提示 LUKS 通關密語;設在 systemd
    # initrd 的 root 使用者上,以避開舊式 boot.initrd.network.ssh.shell 的警告。
    boot.initrd.systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";

    preservation'.os.directories = [ "/etc/secrets/initrd" ];
  };
}
