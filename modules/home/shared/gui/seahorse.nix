{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.seahorse;
in
{
  options.gui.seahorse.enable = lib.mkEnableOption "Seahorse and the GNOME keyring";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.seahorse ];

    persist.directories = lib.mkIf config.persist.enable [
      {
        directory = ".local/share/keyrings";
        mode = "0700";
      }
    ];
  };
}
