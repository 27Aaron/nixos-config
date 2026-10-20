# Claude Desktop:Electron 桌面應用,開自己的視窗,所以放 gui 而不是 tui。
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
  home.packages = [ llm.claude-desktop ];

  # 桌面端的設定與登入態。
  persist'.directories = [ ".config/Claude" ];
}
