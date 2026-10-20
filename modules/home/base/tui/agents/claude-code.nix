# Claude Code:終端裡的 agent。
#
# 非自由軟體,依賴 nixpkgs.config.allowUnfree。
{
  inputs,
  pkgs,
  ...
}:
let
  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [ llm.claude-code ];

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
  };

  # 登入態、設定與工作階段索引;由程式自行寫入,只保留跨重啟。
  # ~/.cache 不登記:留在 tmpfs 上,重開機即清空。
  persist' = {
    directories = [ ".claude" ];
    files = [ ".claude.json" ];
  };
}
