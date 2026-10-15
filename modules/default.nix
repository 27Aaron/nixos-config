{
  lib,
  vars,
  ...
}:
let
  # 遞迴收集此目錄下的所有模組:普通 .nix 檔案,
  # 以及帶有自身 default.nix 的子目錄。
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
  # 主要使用者的選項別名。
  imports = [
    (lib.mkAliasOptionModule [ "user'" ] [ "users" "users" vars.username ])
    (lib.mkAliasOptionModule [ "hm'" ] [ "home-manager" "users" vars.username ])
  ]
  ++ listModules ./.;
}
