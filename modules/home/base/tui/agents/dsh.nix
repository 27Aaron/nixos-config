# dsh:終端裡的 agent harness。
{
  inputs,
  pkgs,
  ...
}:
let
  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [ llm.dsh ];

  # 設定、憑證與工作階段都在 DSH_HOME,預設 ~/.dsh。
  persist'.directories = [ ".dsh" ];
}
