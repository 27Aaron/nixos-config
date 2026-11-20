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

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [ ".config/btop" ];
}
