{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.claude-desktop;

  claude-desktop = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;
in
{
  options.gui'.claude-desktop.enable = lib.mkEnableOption "Claude Desktop";

  config = lib.mkIf cfg.enable {
    # 非自由軟體,需要 nixpkgs.config.allowUnfree。
    home.packages = [ claude-desktop ];

    # 設定與登入狀態。
    persist'.directories = [
      {
        directory = ".config/Claude";
        mode = "0700";
      }
    ];
  };
}
