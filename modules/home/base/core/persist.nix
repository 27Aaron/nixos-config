{ lib, ... }:
let
  # 狀態項目可寫成家目錄相對路徑,或帶屬性的集合。
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
  # 各模組在此回報要跨重啟保留的家目錄路徑,由 NixOS 的 persistence 模組
  # 併入 preservation。enable 由該模組設定,其他平臺維持關閉。
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
