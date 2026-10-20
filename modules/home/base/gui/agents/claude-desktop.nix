# 非自由軟體,需要 nixpkgs.config.allowUnfree。
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
