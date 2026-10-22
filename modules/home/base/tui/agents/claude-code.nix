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
  home.packages = [ llm.claude-code ];

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
  };

  # 登入狀態與設定由程式自行寫入。
  persist' = {
    directories = [ ".claude" ];
    files = [
      {
        file = ".claude.json";
        mode = "0600";
      }
    ];
  };
}
