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
    enable = lib.mkEnableOption "System fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      # 只裝下面清單,不帶入 nixpkgs 的預設字型包。
      enableDefaultPackages = false;
      fontDir.enable = true;

      packages = with pkgs; [
        maple-mono.NF-unhinted
        nerd-fonts.symbols-only

        source-han-sans
        source-han-serif

        fonts.pingfang

        noto-fonts-color-emoji
      ];

      fontconfig.defaultFonts = {
        serif = [
          "Source Han Serif TC"
        ];
        sansSerif = [
          "PingFang TC"
          "Source Han Sans TC"
        ];
        monospace = [ "Maple Mono NF" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
