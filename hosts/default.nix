{
  inputs,
  nixpkgs,
  disko,
  preservation,
  home-manager,
  ...
}:

let
  inherit (nixpkgs) lib;

  hosts = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists ./${name}/default.nix
  ) (builtins.readDir ./.);

  mkHost =
    name: _:
    lib.nixosSystem {
      specialArgs = {
        hostName = name;
        inherit inputs;
        vars = import ../vars;
      };
      modules = [
        ../modules
        disko.nixosModules.default
        preservation.nixosModules.preservation
        home-manager.nixosModules.home-manager
        {
          # 目錄名稱即為主機名稱。
          networking.hostName = lib.mkDefault name;
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";

            # NixOS 的 specialArgs 不會自動傳入 Home Manager 模組,需顯式轉交。
            extraSpecialArgs = {
              inherit inputs;
              vars = import ../vars;
            };
          };
        }
        ./${name}
      ];
    };
in
lib.mapAttrs mkHost hosts
