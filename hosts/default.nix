# 主機探索:hosts/nixos/<名稱>/ 成為 nixosConfigurations.<名稱>,目錄名即主機名。
# hosts/darwin/ 預留給 nix-darwin,加入第一臺 Mac 時在此接上 darwinConfigurations。
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
        secrets = inputs.secrets;
      };
      modules =
        listModules ../modules/base
        ++ listModules ../modules/nixos
        ++ [
          inputs.disko.nixosModules.default
          inputs.preservation.nixosModules.preservation
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          ./nixos/${name}
        ];
    };
in
{
  nixosConfigurations = lib.mapAttrs mkNixos (hostsIn ./nixos);
}
