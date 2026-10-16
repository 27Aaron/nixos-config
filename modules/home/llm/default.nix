{ inputs, pkgs, ... }:
let
  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # claude-code、claude-desktop、chatgpt 為非自由軟體,依賴 nixpkgs.config.allowUnfree。
  home.packages = [
    llm.claude-code
    llm.claude-desktop
    llm.chatgpt
    llm.codex
  ];

  # 登入態與配置由程式自行寫入,只保留跨重啟。
  persist' = {
    directories = [
      {
        directory = ".claude";
        mode = "0700";
      }
      {
        directory = ".codex";
        mode = "0700";
      }
    ];

    files = [
      {
        file = ".claude.json";
        mode = "0600";
      }
    ];
  };

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
    cx = "codex --dangerously-bypass-approvals-and-sandbox";
  };
}
