{ lib }:
let
  vars = import ../../vars;

  # 各主機對外開放的連接埠。服務新開了埠,要在這裡登記才能通過測試。
  # 每臺都開 sshd 與 avahi 的 mDNS。
  openPorts = {
    river = {
      tcp = [ 233 ];
      udp = [ 5353 ];
    };
    router = {
      tcp = [ 233 ];
      udp = [ 5353 ];
    };
    elaina = {
      tcp = [ 233 ];
      udp = [ 5353 ];
    };
  };

  # 存放金鑰、登入狀態或歷史紀錄的路徑;有持久化就必須只限本人讀取。
  privateDirs = [
    ".ssh"
    ".gnupg"
    ".config/gh"
    ".claude"
    ".dsh"
    ".config/Claude"
    ".config/@deepseek-ai/dsh-desktop"
    ".config/magpie"
    ".config/mozilla"
    ".config/google-chrome"
    ".config/Code"
    ".local/share/zed"
    ".local/share/keyrings"
    ".local/share/NagramDesktop"
    ".local/share/atuin"
    ".local/share/fish"
    ".local/share/Steam"
    ".steam"
    "nixos-config"
  ];
  privateFiles = [ ".claude.json" ];
  privateSystemDirs = [
    "/var/lib/bluetooth"
    "/etc/NetworkManager/system-connections"
  ];

  # 每臺主機的核心參數基準與禁止載入的模組。
  kernelSysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.perf_event_paranoid" = 2;
    "kernel.unprivileged_bpf_disabled" = 2;
    "net.core.bpf_jit_harden" = 1;
    "vm.unprivileged_userfaultfd" = 0;
    "dev.tty.ldisc_autoload" = 0;
    "fs.protected_symlinks" = 1;
    "fs.protected_hardlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
  };
  blockedModules = [
    "esp4"
    "esp6"
    "rxrpc"
    "sctp"
    "rds"
    "tipc"
  ];

  sorted = list: lib.sort lib.lessThan (lib.unique list);
in
{
  # 只有 wheel 能連上 daemon:服務帳號即使被攻破,也碰不到 daemon 的提權類
  # 漏洞。root 一律可連線。
  daemon-access =
    { config, ... }:
    {
      expr = config.nix.settings.allowed-users;
      expected = [ "@wheel" ];
    };

  # 只有宣告 rootLogin 的主機接受 root;一律只接受公鑰。直接啟用上游
  # services.openssh 而不經 services'.openssh 的主機也會在這裡失敗。
  ssh =
    { config, ... }:
    let
      cfg = config.services.openssh;
    in
    {
      expr = lib.optionalAttrs cfg.enable {
        inherit (cfg.settings)
          PermitRootLogin
          PasswordAuthentication
          KbdInteractiveAuthentication
          X11Forwarding
          ;
      };
      expected = lib.optionalAttrs cfg.enable {
        PermitRootLogin = if config.services'.openssh.rootLogin then "prohibit-password" else "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
      };
    };

  firewall =
    { config, ... }:
    let
      fw = config.networking.firewall;
      inherit (config.networking) hostName;
      ports =
        openPorts.${hostName} or (throw "tests/security/nixos.nix: 請在 openPorts 登記 ${hostName} 開放的連接埠");
    in
    {
      expr = {
        inherit (fw)
          enable
          allowedTCPPortRanges
          allowedUDPPortRanges
          interfaces
          trustedInterfaces
          ;
        tcp = sorted fw.allowedTCPPorts;
        udp = sorted fw.allowedUDPPorts;
      };
      expected = {
        enable = true;
        allowedTCPPortRanges = [ ];
        allowedUDPPortRanges = [ ];
        interfaces = { };
        # lo 由 NixOS 的防火牆模組預設信任。
        trustedInterfaces = [ "lo" ];
        tcp = sorted ports.tcp;
        udp = sorted ports.udp;
      };
    };

  # systemd-boot 的編輯器能改核心參數(例如 init=/bin/sh),等同免密碼 root;
  # 帳號只能由設定宣告。
  boot-and-accounts =
    { config, ... }:
    let
      loader = config.boot.loader.systemd-boot;
    in
    {
      expr = {
        editor = loader.enable && loader.editor;
        inherit (config.users) mutableUsers;
      };
      expected = {
        editor = false;
        mutableUsers = false;
      };
    };

  # 密碼不可寫在設定裡(會進所有人可讀的 /nix/store),一律由 sops 在建立
  # 帳號前解密;只比對是否設定,失敗訊息才不會印出雜湊。
  password-source =
    { config, ... }:
    let
      inline =
        user:
        lib.any (option: user.${option} != null) [
          "hashedPassword"
          "password"
          "initialPassword"
          "initialHashedPassword"
        ];
      accounts = [
        "root"
        vars.username
      ];
    in
    {
      expr = lib.genAttrs accounts (
        name:
        let
          user = config.users.users.${name};
        in
        {
          inline = inline user;
          inherit (user) hashedPasswordFile;
        }
      );
      expected = lib.genAttrs accounts (_: {
        inline = false;
        hashedPasswordFile = "/run/secrets-for-users/hashedPassword";
      });
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
        sshKeyPaths = [ "/persistent/home/${vars.username}/.ssh/id_ed25519" ];
        generateKey = false;
      };
    };

  # btrbk 以自己的帳號經 sudo 呼叫 btrfs,開啟 execWheelOnly 會讓快照失敗。
  btrbk-sudo =
    { config, ... }:
    {
      expr = config.services.btrbk.instances != { } && config.security.sudo.execWheelOnly;
      expected = false;
    };

  # 模組只靠 blacklist 擋不住明確的 modprobe,要同時有 install 規則。
  kernel =
    host@{ config, ... }:
    let
      blocked =
        module:
        lib.elem module config.boot.blacklistedKernelModules
        && lib.hasInfix "install ${module} " config.boot.extraModprobeConfig;
    in
    {
      expr = {
        sysctl = lib.mapAttrs (key: _: config.boot.kernel.sysctl.${key} or null) kernelSysctl;
        modules = lib.genAttrs blockedModules blocked;
        # Nix 的建置沙箱需要 user namespaces;休眠需要可寫入的核心映像。
        inherit (config.security) allowUserNamespaces;
        protectKernelImage = config.boot.resumeDevice != "" && config.security.protectKernelImage;
        # 一般的主機設定就能覆寫基準,不需要 mkForce。
        hostOverride =
          (host.extendModules {
            modules = [ { boot.kernel.sysctl."fs.protected_regular" = 1; } ];
          }).config.boot.kernel.sysctl."fs.protected_regular";
      };
      expected = {
        sysctl = kernelSysctl;
        modules = lib.genAttrs blockedModules (_: true);
        allowUserNamespaces = true;
        protectKernelImage = false;
        hostOverride = 1;
      };
    };

  # preservation 對未宣告的目錄每次開機都套用 0755。
  private-state =
    { config, ... }:
    let
      preserved =
        config.preservation.preserveAt."/persistent" or {
          directories = [ ];
          users = { };
        };
      user =
        preserved.users.${vars.username} or {
          directories = [ ];
          files = [ ];
        };
      home = config.users.users.${vars.username}.home;

      modes = key: entries: lib.listToAttrs (map (e: lib.nameValuePair e.${key} e.mode) entries);
      actual =
        modes "directory" user.directories
        // modes "file" user.files
        // modes "directory" preserved.directories;

      wanted =
        lib.genAttrs (map (d: "${home}/${d}") privateDirs ++ privateSystemDirs) (_: "0700")
        // lib.genAttrs (map (f: "${home}/${f}") privateFiles) (_: "0600");
      # 沒有持久化的路徑不會留在磁碟上,不需檢查。
      present = lib.filterAttrs (path: _: actual ? ${path}) wanted;
    in
    {
      expr = lib.mapAttrs (path: _: actual.${path}) present;
      expected = present;
    };
}
