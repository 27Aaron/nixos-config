# 倉庫共用的輔助函式,由 hosts/default.nix 與各平臺入口匯入。
{ lib }:
let
  # 遞迴收集模組:一般 .nix 檔,以及含 default.nix 的子目錄(不再深入)。
  listModules =
    dir:
    lib.pipe (builtins.readDir dir) [
      (lib.filterAttrs (name: _: name != "default.nix"))
      (lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
          isNixDir = builtins.pathExists (path + "/default.nix");
          isNixFile = type == "regular" && lib.hasSuffix ".nix" name;
        in
        if type == "directory" then
          if isNixDir then path else listModules path
        else
          lib.optional isNixFile path
      ))
      lib.flatten
    ];
in
{
  inherit listModules;
}
