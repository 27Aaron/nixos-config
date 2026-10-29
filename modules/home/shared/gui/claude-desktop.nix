{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.claude-desktop;

  claude-desktop = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;
in
{
  options.gui.claude-desktop.enable = lib.mkEnableOption "Claude Desktop";

  config = lib.mkIf cfg.enable {
    home.packages = [ claude-desktop ];

    persist.directories = lib.mkIf config.persist.enable [
      {
        directory = ".config/Claude";
        mode = "0700";
      }
    ];
  };
}
