# 非自由軟體,需要 nixpkgs.config.allowUnfree。
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.claude-desktop;

  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.gui'.claude-desktop.enable = lib.mkEnableOption "Claude Desktop";

  config = lib.mkIf cfg.enable {
    home.packages = [ llm.claude-desktop ];

    # 設定與登入狀態。
    persist'.directories = [ ".config/Claude" ];
  };
}
