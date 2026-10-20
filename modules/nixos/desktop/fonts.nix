{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.fonts;
in
{
  options.desktop'.fonts = {
    enable = lib.mkEnableOption "System fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      # 下面的清單就是全部字型,不帶入 nixpkgs 的預設字型包。
      enableDefaultPackages = false;
      fontDir.enable = true;

      packages = with pkgs; [
        # 等寬,含圖示字形;kitty 也用這個家族名,中文回退到思源。
        maple-mono.NF-unhinted
        nerd-fonts.symbols-only

        # 中文:思源黑體與思源宋體。
        source-han-sans
        source-han-serif

        # Emoji。
        noto-fonts-color-emoji
      ];

      # 中文用思源,繁體在前。
      fontconfig.defaultFonts = {
        serif = [
          "Source Han Serif TC"
          "Source Han Serif SC"
        ];
        sansSerif = [
          "Source Han Sans TC"
          "Source Han Sans SC"
        ];
        monospace = [ "Maple Mono NF" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
