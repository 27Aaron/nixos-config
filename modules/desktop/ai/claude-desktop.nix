{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.claude-desktop;

  claude-desktop = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;
in
{
  options.desktop'.claude-desktop.enable = lib.mkEnableOption "Claude Desktop";

  config = lib.mkIf cfg.enable {
    hm'.home.packages = [ claude-desktop ];

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".config/Claude";
        mode = "0700";
      }
    ];
  };
}
