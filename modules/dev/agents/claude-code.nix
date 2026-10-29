{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dev'.claude-code;

  claude-code = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
in
{
  options.dev'.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf cfg.enable {
    hm'.home.packages = [ claude-code ];

    # auto 模式逐一審查動作:例行操作直接放行,有風險的會被擋下。不用
    # bypassPermissions,它完全不檢查,倉庫或網頁裡的提示注入可以直接執行指令。
    hm'.home.shellAliases = {
      cc = "claude --permission-mode auto";
    };

    preservation'.user = lib.mkIf config.hardware'.persistence.enable {
      directories = [
        {
          directory = ".claude";
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
  };
}
