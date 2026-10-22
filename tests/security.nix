{ lib }:
let
  vars = import ../vars;

  # 各主機對外開放的連接埠。服務新開了埠,要在這裡登記才能通過測試。
  openPorts = {
    # sshd 233;dae 的 tproxy 12345。
    river = {
      tcp = [
        233
        12345
      ];
      udp = [ 12345 ];
    };
  };

  # 每個快取都能把任意 store 路徑送進系統並以 root 執行;新增時要同時改
  # modules/base/core/nix.nix 與這裡。
  caches = {
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.numtide.com"
      "https://fcitx5-vinput.cachix.org"
    ];
    keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="
    ];
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
    "nixos-config"
  ];
  privateFiles = [ ".claude.json" ];
  privateSystemDirs = [
    "/var/lib/sops-nix"
    "/var/lib/bluetooth"
    "/etc/NetworkManager/system-connections"
  ];

  sorted = list: lib.sort lib.lessThan (lib.unique list);
in
{
  # 受信任的使用者能停用簽章檢查、匯入任意 store 路徑,等同免密碼 root。
  nix-trust =
    { config, ... }:
    {
      expr = {
        inherit (config.nix.settings) trusted-users allowed-users require-sigs;
      };
      expected = {
        trusted-users = [ "root" ];
        allowed-users = [ "@wheel" ];
        require-sigs = true;
      };
    };

  # 上游模組或 flake 輸入新增的快取也會被抓到。
  nix-caches =
    { config, ... }:
    let
      s = config.nix.settings;
    in
    {
      expr = {
        substituters = sorted (s.substituters ++ s.extra-substituters ++ s.trusted-substituters);
        keys = sorted (s.trusted-public-keys ++ s.extra-trusted-public-keys);
      };
      expected = lib.mapAttrs (_: sorted) caches;
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
      ports = openPorts.${hostName} or (throw "tests/security.nix: 請在 openPorts 登記 ${hostName} 開放的連接埠");
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

  # btrbk 以自己的帳號經 sudo 呼叫 btrfs,開啟 execWheelOnly 會讓快照失敗。
  btrbk-sudo =
    { config, ... }:
    {
      expr = config.services.btrbk.instances != { } && config.security.sudo.execWheelOnly;
      expected = false;
    };

  # 開啟倉庫不能直接執行程式碼:編輯器保持信任確認,代理不略過權限檢查。
  # Zed 的值要明確寫 false,因為 Home Manager 只會合併、不會刪除既有的鍵。
  editor-and-agent-trust =
    { config, ... }:
    let
      hm = config.home-manager.users.${vars.username};
      zed = hm.programs.zed-editor;
      vscode = hm.programs.vscode;
      aliases = hm.home.shellAliases // hm.programs.fish.shellAliases // hm.programs.zsh.shellAliases;
      bypasses =
        cmd: lib.hasInfix "dangerously-skip-permissions" cmd || lib.hasInfix "bypassPermissions" cmd;
    in
    {
      expr = {
        zed = lib.optionalAttrs zed.enable {
          trust_all_worktrees = zed.userSettings.session.trust_all_worktrees or null;
        };
        vscode = lib.optionalAttrs vscode.enable {
          workspaceTrust = vscode.profiles.default.userSettings."security.workspace.trust.enabled" or true;
        };
        bypassAliases = lib.filterAttrs (_: bypasses) aliases;
      };
      expected = {
        zed = lib.optionalAttrs zed.enable { trust_all_worktrees = false; };
        vscode = lib.optionalAttrs vscode.enable { workspaceTrust = true; };
        bypassAliases = { };
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
