{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.dsh-desktop;

  nur = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.gui'.dsh-desktop.enable = lib.mkEnableOption "the DeepSeek dsh desktop app";

  config = lib.mkIf cfg.enable {
    home.packages = [ nur.dsh-desktop ];

    # Electron 設定與崩潰紀錄。
    persist'.directories = [ ".config/@deepseek-ai/dsh-desktop" ];
  };
}
