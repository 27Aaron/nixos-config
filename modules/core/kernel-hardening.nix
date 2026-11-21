{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.core'.kernel;
in
{
  options.core'.kernel.blockedModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "esp4"
      "esp6"
      "rxrpc"
      "sctp"
      "rds"
      "tipc"
    ];
    description = ''
      Kernel modules that may not be loaded, not even with an explicit
      modprobe. Linux loads protocol modules on demand, and unprivileged users
      can trigger that through sockets or user namespaces, so a module nobody
      uses is still attack surface until a fix is installed and booted. The
      defaults are rarely used protocols with a record of privilege escalation
      bugs: IPsec ESP and RxRPC (Dirty Frag, CVE-2026-43284 and
      CVE-2026-43500), SCTP, RDS and TIPC. Remove a module on a host that needs
      it, for example ESP for an IPsec VPN such as strongSwan.
    '';
  };

  config = {
    # 明確宣告,不依賴核心編譯選項或 systemd 的預設。
    boot.kernel.sysctl =
      lib.mapAttrs (_: lib.mkDefault) {
        "kernel.dmesg_restrict" = 1;
        "kernel.yama.ptrace_scope" = 1;
        "kernel.perf_event_paranoid" = 2;
        # 停用非特權 bpf();設 2 讓管理者不必重開機就能暫時改回。
        "kernel.unprivileged_bpf_disabled" = 2;
        # 1 只強化非特權程式的 JIT,不拖慢 root 載入的 eBPF。
        "net.core.bpf_jit_harden" = 1;
        "vm.unprivileged_userfaultfd" = 0;
        # 一般使用者曾藉此載入有漏洞的 n_hdlc。
        "dev.tty.ldisc_autoload" = 0;
        # 2 連群組可寫的黏滯目錄也涵蓋。
        "fs.protected_symlinks" = 1;
        "fs.protected_hardlinks" = 1;
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;
      }
      // {
        # nixpkgs 已用 mkDefault 設成 1,再寫一個 mkDefault 會衝突。
        # 999 比一般定義弱,主機可以直接覆寫。2 連 root 也看不到核心指標。
        "kernel.kptr_restrict" = lib.mkOverride 999 2;
      };

    # blacklist 只擋自動載入;install 改成 false,明確的 modprobe 也會失敗。
    boot.blacklistedKernelModules = cfg.blockedModules;
    boot.extraModprobeConfig = lib.concatMapStrings (
      module: "install ${module} ${pkgs.coreutils}/bin/false\n"
    ) cfg.blockedModules;

    # 刻意不做:不關 user namespaces(Nix 的建置沙箱需要)、不開
    # security.protectKernelImage(會停用休眠)、不換 hardened kernel。
  };
}
