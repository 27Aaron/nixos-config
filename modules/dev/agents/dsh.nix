{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development'.dsh;

  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
in
{
  options.development'.dsh.enable = lib.mkEnableOption "the DeepSeek dsh agent";

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
