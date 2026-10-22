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

  # 設定與登入狀態。
  persist'.directories = [ ".config/Claude" ];
}
