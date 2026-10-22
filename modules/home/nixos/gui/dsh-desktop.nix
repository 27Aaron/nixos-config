{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.dsh-desktop;

  dsh-desktop = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.dsh-desktop;
in
{
  options.gui'.dsh-desktop.enable = lib.mkEnableOption "the DeepSeek dsh desktop app";

  config = lib.mkIf cfg.enable {
    home.packages = [ dsh-desktop ];

    # Electron 設定與崩潰紀錄。
    persist'.directories = [ ".config/@deepseek-ai/dsh-desktop" ];
  };
}
