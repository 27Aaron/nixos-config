{ inputs, pkgs, ... }:
let
  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  nur = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # claude-code、claude-desktop 為非自由軟體,依賴 nixpkgs.config.allowUnfree。
  home.packages = [
    llm.claude-code
    llm.claude-desktop
    llm.dsh
    nur.dsh-desktop
  ];

  # 登入態與配置由程式自行寫入,只保留跨重啟。
  # 快取一律不登記:~/.cache 留在 tmpfs 上,重開機即清空。
  persist' = {
    directories = [
      ".claude"
      # Claude 桌面端的設定。
      ".config/Claude"
      # dsh 的設定、憑證與工作階段都在 DSH_HOME,預設 ~/.dsh。
      ".dsh"
      # dsh-desktop 的 Electron 設定與崩潰紀錄。
      ".config/@deepseek-ai/dsh-desktop"
    ];

    files = [
      ".claude.json"
    ];
  };

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
  };
}
