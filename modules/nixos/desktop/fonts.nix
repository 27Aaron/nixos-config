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
    enable = lib.mkEnableOption "System fonts configuration";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      # The explicit list below is the whole font set; this keeps the default
      # packages out so the closure stays predictable.
      enableDefaultPackages = false;
      fontDir.enable = true;

      packages = with pkgs; [
        dejavu_fonts
        fira-code
        font-awesome
        inter
        julia-mono
        lxgw-wenkai
        maple-mono.NF-CN-unhinted
        material-design-icons
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
        noto-fonts-color-emoji
        source-han-sans
        source-han-serif
        source-sans
        source-serif
      ];

      fontconfig.defaultFonts = {
        serif = [
          "LXGW WenKai"
          "Source Han Serif SC"
          "Source Han Serif TC"
        ];
        sansSerif = [
          "LXGW WenKai"
          "Source Han Sans SC"
          "Source Han Sans TC"
        ];
        monospace = [ "Maple Mono NF CN" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
