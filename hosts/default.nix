{ inputs }:

let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../lib { inherit lib; }) listModules;

  vars = import ../vars;

  # modules/ 底下除了 home/ 都是系統模組;home/ 由 core/home-manager.nix 載入。
  systemModules = lib.pipe (builtins.readDir ../modules) [
    (lib.filterAttrs (name: type: type == "directory" && name != "home"))
    lib.attrNames
    (lib.concatMap (name: listModules ../modules/${name}))
  ];

  hostsIn =
    dir:
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (dir + "/${name}/default.nix")
    ) (builtins.readDir dir);

  mkNixos =
    name: _:
    lib.nixosSystem {
      specialArgs = {
        hostName = name;
        inherit inputs vars;
      };
      modules = systemModules ++ [ ./${name} ];
    };
in
{
  nixosConfigurations = lib.mapAttrs mkNixos (hostsIn ./.);
}
