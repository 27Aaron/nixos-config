{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.seahorse;
in
{
  options.desktop'.seahorse.enable = lib.mkEnableOption "Seahorse and the GNOME keyring";

  config = lib.mkIf cfg.enable {
    hm'.home.packages = [ pkgs.seahorse ];

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".local/share/keyrings";
        mode = "0700";
      }
    ];
  };
}
