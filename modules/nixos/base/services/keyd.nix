{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.keyd;
  ini = pkgs.formats.ini { };
in
{
  options.services'.keyd = {
    enable = lib.mkEnableOption "keyd, a system-wide key remapping daemon";

    keyboards = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            ids = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "*" ];
              description = "Device IDs to manage, in keyd(1) syntax.";
            };

            settings = lib.mkOption {
              inherit (ini) type;
              default = { };
              description = "Per-keyboard keyd settings, without the ids section.";
            };

            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Extra lines appended to the generated file.";
            };
          };
        }
      );
      default = { };
      description = "Keyboards to configure, keyed by file name under /etc/keyd/.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;
      keyboards = cfg.keyboards;
    };
  };
}
