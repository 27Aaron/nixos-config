{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tui'.monitoring;
in
{
  options.tui'.monitoring.enable = lib.mkEnableOption "interactive system monitors";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      btop
      ncdu
      nload
    ];

    # btop 會在介面中直接改寫設定檔。
    persist'.directories = [ ".config/btop" ];
  };
}
