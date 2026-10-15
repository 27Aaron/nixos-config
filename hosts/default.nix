{
  nixpkgs,
  disko,
  preservation,
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
        vars = import ../vars;
      };
      modules = [
        disko.nixosModules.default
        preservation.nixosModules.preservation
        {
          # The directory name is the hostname.
          networking.hostName = lib.mkDefault name;
        }
        ./${name}
      ];
    };
in
lib.mapAttrs mkHost hosts
