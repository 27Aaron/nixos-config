{ lib }:
let
  findHosts =
    root:
    if !(builtins.pathExists root) then
      [ ]
    else
      lib.concatLists (
        lib.mapAttrsToList (
          name: type:
          let
            path = root + "/${name}";
          in
          if
            type != "directory"
            || lib.hasPrefix "." name
            || builtins.elem name [
              "common"
              "profiles"
              "lib"
            ]
          then
            [ ]
          else if builtins.pathExists (path + "/default.nix") then
            [
              {
                inherit name;
                value = import (path + "/default.nix");
              }
            ]
          else
            findHosts path
        ) (builtins.readDir root)
      );
in
{
  discover =
    root:
    let
      hosts = findHosts root;
      names = map (host: host.name) hosts;
    in
    if builtins.length names != builtins.length (lib.unique names) then
      throw "duplicate host name discovered under ${toString root}"
    else
      builtins.listToAttrs hosts;
}
