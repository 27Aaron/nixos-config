{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tui.dsh;

  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
in
{
  options.tui.dsh.enable = lib.mkEnableOption "the DeepSeek dsh agent";

  config = lib.mkIf cfg.enable {
    home.packages = [ dsh ];

    persist.directories = lib.mkIf config.persist.enable [
      {
        directory = ".dsh";
        mode = "0700";
      }
    ];
  };
}
