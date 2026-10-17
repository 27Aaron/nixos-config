{ inputs, pkgs, ... }:
let
  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # claude-code、claude-desktop 為非自由軟體,依賴 nixpkgs.config.allowUnfree。
  home.packages = [
    llm.claude-code
    llm.claude-desktop
    llm.dsh
  ];

  # 登入態與配置由程式自行寫入,只保留跨重啟。
  persist' = {
    directories = [
      ".claude"
      # Claude 桌面端的設定與快取。
      ".config/Claude"
      ".cache/Claude"
      # dsh 的設定、憑證與工作階段都在 DSH_HOME,預設 ~/.dsh。
      ".dsh"
    ];

    files = [
      ".claude.json"
    ];
  };

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
  };
}
