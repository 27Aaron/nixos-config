{ inputs }:

let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../lib { inherit lib; }) listModules;

  vars = import ../vars;

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
      modules = listModules ../modules/base ++ listModules ../modules/nixos ++ [ ./nixos/${name} ];
    };
in
{
  # hosts/nixos/<名稱>/ 成為 nixosConfigurations.<名稱>。
  nixosConfigurations = lib.mapAttrs mkNixos (hostsIn ./nixos);
}
