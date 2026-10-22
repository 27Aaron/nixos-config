{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tui'.claude-code;

  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.tui'.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf cfg.enable {
    # 非自由軟體,需要 nixpkgs.config.allowUnfree。
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
  };
}
