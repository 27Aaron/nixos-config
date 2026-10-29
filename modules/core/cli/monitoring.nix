{
  config,
  lib,
  pkgs,
  ...
}:
{
  hm'.home.packages = with pkgs; [
    btop
    ncdu
    nload
  ];

  # btop 會在介面中直接改寫設定檔。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [ ".config/btop" ];
}
