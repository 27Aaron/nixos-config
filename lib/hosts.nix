# Host inventory. Each directory under hosts/<platform> describes one machine
# with a small data file instead of an arbitrary module, so a host states what
# it is and the flake decides how to build it.
{
  lib,
  profiles,
  vars,
}:
let
  requiredFields = [
    "system"
    "stateVersion"
    "profiles"
  ];

  loadHost =
    platform: name:
    let
      host = import (../hosts + "/${platform}/${name}/default.nix") {
        inherit lib profiles vars;
      };
      missing = builtins.filter (field: !(host ? ${field})) requiredFields;
    in
    if missing != [ ] then
      throw "host ${platform}/${name}: missing required field(s): ${lib.concatStringsSep ", " missing}"
    else
      host
      // {
        inherit name platform;
        home = host.home or [ ];
        modules = host.modules or [ ];
        hardware = host.hardware or { };
        homeStateVersion = host.homeStateVersion or "26.05";
      };

  loadPlatform =
    platform:
    let
      root = ../hosts + "/${platform}";
    in
    if !(builtins.pathExists root) then
      { }
    else
      lib.mapAttrs (name: _: loadHost platform name) (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir root)
      );

  nixos = loadPlatform "nixos";
  darwin = loadPlatform "darwin";
  duplicates = lib.intersectLists (lib.attrNames nixos) (lib.attrNames darwin);
in
if duplicates != [ ] then
  throw "host name(s) used on more than one platform: ${lib.concatStringsSep ", " duplicates}"
else
  nixos // darwin
