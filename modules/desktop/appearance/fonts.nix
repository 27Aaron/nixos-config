{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.fonts;

  fonts = inputs.fonts.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.desktop'.fonts = {
    enable = lib.mkEnableOption "the system fonts and fontconfig defaults";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = false;
      fontDir.enable = true;

      packages = with pkgs; [
        maple-mono.NF-unhinted
        nerd-fonts.symbols-only

        fonts.lxgw-wenkai-tc
        fonts.lxgw-wenkai

        noto-fonts
        noto-fonts-color-emoji
      ];

      fontconfig.defaultFonts = {
        serif = [
          "LXGW WenKai TC"
          "LXGW WenKai"
        ];
        sansSerif = [
          "LXGW WenKai TC"
          "LXGW WenKai"
        ];
        monospace = [ "Maple Mono NF" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # 系統字型快取在 store 裡,使用者快取仍會在第一次畫字時重建。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".cache/fontconfig"
    ];
  };
}
