{
  description = "Aaron's Nix configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation = {
      url = "github:nix-community/preservation";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-hardware,
      disko,
      preservation,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      vars = import ./vars;

      # Discover host specifications from the directory tree.
      hostLib = import ./lib/hosts.nix { inherit lib; };

      nixosHosts = hostLib.discover ./hosts/nixos;
      darwinHosts = hostLib.discover ./hosts/darwin;

      # Build each host from its declared system and module list.
      mkNixosConfiguration =
        hostName: host:
        nixpkgs.lib.nixosSystem {
          system = host.system;
          specialArgs = {
            inherit disko preservation hostName;
            nixosHardware = nixos-hardware;
          }
          // vars
          // (host.specialArgs or { });
          modules = [ home-manager.nixosModules.home-manager ] ++ host.modules;
        };

      mkDarwinConfiguration =
        hostName: host:
        nix-darwin.lib.darwinSystem {
          system = host.system;
          specialArgs = {
            inherit hostName;
          }
          // vars
          // (host.specialArgs or { });
          modules = [
            home-manager.darwinModules.home-manager
            ./profiles/darwin
          ]
          ++ host.modules;
        };

      forEachSystem = lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      nixosConfigurations = lib.mapAttrs mkNixosConfiguration nixosHosts;
      darwinConfigurations = lib.mapAttrs mkDarwinConfiguration darwinHosts;

      formatter = forEachSystem (
        system:
        nixpkgs.legacyPackages.${system}.nixfmt-tree.override {
          nixfmtPackage = nixpkgs.legacyPackages.${system}.nixfmt-rs;
        }
      );

    };
}
