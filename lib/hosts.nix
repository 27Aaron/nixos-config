# Host inventory. Each directory under hosts/<platform> describes one machine
# with a small data file instead of an arbitrary module; parts/host-options.nix
# declares the shape that data has to match.
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

  # Fields the inventory reads; everything else a host file says is applied as a
  # module, so per-host switches can be written straight into the data file.
  hostFields = [
    "system"
    "stateVersion"
    "homeStateVersion"
    "timeZone"
    "profiles"
    "imports"
    "hardware"
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
      lib.filterAttrs (field: _: builtins.elem field hostFields) host
      // {
        inherit name platform;
        settings = builtins.removeAttrs host hostFields;
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
