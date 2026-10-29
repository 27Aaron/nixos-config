{ lib, ... }:
let
  entryType =
    kind:
    lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;

      options.${kind} = lib.mkOption {
        type = lib.types.str;
        description = "Home-relative path of the ${kind} to preserve.";
      };
    };
in
{
  # 由系統的 persistence 模組開啟並併入 preservation。
  options.persist = {
    enable = lib.mkEnableOption "reporting home state to the NixOS persistence module";

    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "directory"));
      default = [ ];
      description = "Directories to preserve in the home directory.";
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "file"));
      default = [ ];
      description = "Files to preserve in the home directory.";
    };
  };
}
