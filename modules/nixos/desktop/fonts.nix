{
  config,
  inputs,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.desktop'.fonts;

  fonts = inputs.fonts.packages.${pkgs.stdenv.hostPlatform.system};
  names = vars.appearance.fonts;
in
{
  options.desktop'.fonts = {
    enable = lib.mkEnableOption "System fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      # 只安裝下列字型,不含 nixpkgs 預設字型。
      enableDefaultPackages = false;
      fontDir.enable = true;

      packages = with pkgs; [
        maple-mono.NF-unhinted
        nerd-fonts.symbols-only

        fonts.lxgw-wenkai-tc
        fonts.lxgw-wenkai

        noto-fonts-color-emoji
      ];

      fontconfig.defaultFonts = {
        serif = [
          names.sans
          names.sansSimplified
        ];
        sansSerif = [
          names.sans
          names.sansSimplified
        ];
        monospace = [ names.mono ];
        emoji = [ names.emoji ];
      };
    };
  };
}
