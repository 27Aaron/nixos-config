{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.dsh-desktop;

  dsh-desktop = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.dsh-desktop;
in
{
  options.desktop'.dsh-desktop.enable = lib.mkEnableOption "the DeepSeek dsh desktop app";

  config = lib.mkIf cfg.enable {
    hm'.home.packages = [ dsh-desktop ];

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".config/@deepseek-ai/dsh-desktop";
        mode = "0700";
      }
    ];
  };
}
