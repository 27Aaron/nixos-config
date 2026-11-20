{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server'.initrd-ssh;

  ssh-keygen = lib.getExe' pkgs.openssh "ssh-keygen";
  coreutils = "${pkgs.coreutils}/bin";
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

    # initrd 的主機私鑰會以明文附加到未加密 ESP 上的 initrd,必須與系統的
    # 主機金鑰分開,不可共用。開機載入程式在 activation 之前就把私鑰附加進
    # initrd,缺檔時要在 pre-switch 補上;持久目錄此時可能還沒 bind 上來,
    # 先寫進 /persistent,再供本次安裝讀取。
    system.preSwitchChecks.initrd-ssh-host-key = lib.concatMapStrings (path: ''
      key=${lib.escapeShellArg path}
      if [ ! -f "$key" ]; then
        dir=$(${coreutils}/dirname "$key")
        name=$(${coreutils}/basename "$key")
        ${coreutils}/install -d -m 0700 "$dir"
        if [ -d /persistent ]; then
          stored="/persistent$dir"
          ${coreutils}/install -d -m 0700 "$stored"
          if [ ! -f "$stored/$name" ]; then
            ${ssh-keygen} -q -t ed25519 -N "" -f "$stored/$name"
          fi
          if [ ! -f "$key" ]; then
            ${coreutils}/cp -a "$stored/$name" "$key"
            ${coreutils}/cp -a "$stored/$name.pub" "$key.pub"
          fi
        else
          ${ssh-keygen} -q -t ed25519 -N "" -f "$key"
        fi
        ${coreutils}/chmod 0600 "$key"
      fi
    '') (lib.filter (path: lib.isString path && !lib.hasPrefix "/nix/store/" path) cfg.hostKeys);

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/etc/secrets/initrd";
        mode = "0700";
      }
    ];
  };
}
