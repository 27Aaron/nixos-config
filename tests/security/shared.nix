{ lib }:
let
  vars = import ../../vars;

  # 每個快取都能把任意 store 路徑送進系統並以 root 執行;新增時要同時改
  # modules/base/core/nix.nix(或啟用它的模組)與這裡。
  caches = {
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.numtide.com"
    ];
    keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # 只有啟用 desktop'.vinput 的主機才信任,見 WA-001。
  vinputCache = {
    substituters = [ "https://fcitx5-vinput.cachix.org" ];
    keys = [ "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU=" ];
  };

  # 必須包在 nixpak 沙箱裡安裝的程式,值為比對套件名稱的正規表示式。
  sandboxedApps = {
    nagram = "nagram.*";
  };

  sorted = list: lib.sort lib.lessThan (lib.unique list);
in
{
  # 受信任的使用者能停用簽章檢查、匯入任意 store 路徑,等同免密碼 root。
  # 誰能連上 daemon 見 nixos.nix 的 daemon-access。
  nix-trust =
    { config, ... }:
    {
      expr = {
        inherit (config.nix.settings) trusted-users require-sigs;
      };
      expected = {
        trusted-users = [ "root" ];
        require-sigs = true;
      };
    };

  # 上游模組或 flake 輸入新增的快取也會被抓到。
  nix-caches =
    { config, ... }:
    let
      s = config.nix.settings;
      vinput = config.desktop'.vinput.enable or false;
    in
    {
      expr = {
        substituters = sorted (s.substituters ++ s.extra-substituters ++ s.trusted-substituters);
        keys = sorted (s.trusted-public-keys ++ s.extra-trusted-public-keys);
      };
      expected = lib.mapAttrs (
        name: list: sorted (list ++ lib.optionals vinput vinputCache.${name})
      ) caches;
    };

  # 這些程式只能以 nixpak 沙箱版本安裝;換回原始套件時就會失敗。
  sandboxed-apps =
    { config, ... }:
    let
      names = map (p: p.name or "") config.home-manager.users.${vars.username}.home.packages;
      unsandboxed =
        pattern:
        lib.filter (name: builtins.match pattern name != null && !lib.hasPrefix "nixpak-" name) names;
    in
    {
      expr = lib.mapAttrs (_: unsandboxed) sandboxedApps;
      expected = lib.mapAttrs (_: _: [ ]) sandboxedApps;
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
}
