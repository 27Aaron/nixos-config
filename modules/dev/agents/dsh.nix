{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dev'.dsh;

  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
in
{
  options.dev'.dsh.enable = lib.mkEnableOption "the DeepSeek dsh agent";

  config = lib.mkIf cfg.enable {
    hm'.home.packages = [ dsh ];

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".dsh";
        mode = "0700";
      }
    ];
  };
}
