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
      # 只裝下面清單,不帶入 nixpkgs 的預設字型包。
      enableDefaultPackages = false;
      fontDir.enable = true;

      packages = with pkgs; [
        # kitty 與 zed 以這個家族名指定字型,中文回退到思源。
        maple-mono.NF-unhinted
        nerd-fonts.symbols-only

        source-han-sans
        source-han-serif

        noto-fonts-color-emoji
      ];

      # 繁體排在簡體前面,才會先挑到 TC。
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
