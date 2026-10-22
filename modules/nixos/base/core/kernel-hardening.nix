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
    # 明確宣告,不依賴核心編譯選項或 systemd 的預設;主機可直接覆寫。
    # kernel.kptr_restrict 維持 NixOS 預設的 1:設成 2 連 root 讀到的
    # /proc/kallsyms 都是 0,而 dae 的 eBPF 函式庫會讀它。
    # 移除條件見 WORKAROUNDS.md 的 WA-013。
    boot.kernel.sysctl = lib.mapAttrs (_: lib.mkDefault) {
      # 核心日誌只給有 CAP_SYSLOG 的程序讀取。
      "kernel.dmesg_restrict" = 1;
      # 只能 ptrace 自己的子程序;除錯器附加到其他程序需要 sudo。
      "kernel.yama.ptrace_scope" = 1;
      "kernel.perf_event_paranoid" = 2;
      # 停用非特權 bpf();設 2 讓管理者不必重開機就能暫時改回。
      "kernel.unprivileged_bpf_disabled" = 2;
      # 只強化非特權程式的 JIT,不拖慢 dae 以 root 載入的 eBPF。
      "net.core.bpf_jit_harden" = 1;
      "vm.unprivileged_userfaultfd" = 0;
      # 只有 root 能觸發載入 tty 線路規則模組;一般使用者曾藉此載入有漏洞的
      # n_hdlc。
      "dev.tty.ldisc_autoload" = 0;
      # 阻擋在所有人可寫的黏滯目錄(如 /tmp)以連結或預先建立的檔案攻擊其他
      # 帳號;2 連群組可寫的黏滯目錄也涵蓋。
      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
    };

    # blacklist 只擋自動載入;install 改成 false,明確的 modprobe 也會失敗。
    boot.blacklistedKernelModules = cfg.blockedModules;
    boot.extraModprobeConfig = lib.concatMapStrings (
      module: "install ${module} ${pkgs.coreutils}/bin/false\n"
    ) cfg.blockedModules;

    # 刻意不做:不關 user namespaces(Nix 的建置沙箱需要)、不開
    # security.protectKernelImage(會停用休眠)、不換 hardened kernel;也不調
    # 網路相關的 sysctl,dae 的 auto_config_kernel_parameter 會自行調整轉送參數。
  };
}
