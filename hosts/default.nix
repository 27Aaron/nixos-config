{ inputs }:

let
  inherit (inputs.nixpkgs) lib;

  vars = import ../vars;

  hosts = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists ./${name}/default.nix
  ) (builtins.readDir ./.);

  mkHost =
    name: _:
    lib.nixosSystem {
      specialArgs = {
        hostName = name;
        inherit inputs;
        secrets = inputs.secrets;
        inherit vars;
      };
      modules = [
        ../modules
        inputs.disko.nixosModules.default
        inputs.preservation.nixosModules.preservation
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";

            # NixOS 的 specialArgs 不會自動傳入 Home Manager 模組,需顯式轉交。
            extraSpecialArgs = {
              inherit inputs vars;
            };
          };
        }
        ./${name}
      ];
    };
in
lib.mapAttrs mkHost hosts
