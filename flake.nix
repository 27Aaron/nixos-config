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
      profiles = import ./profiles;

      # Hosts are discovered from hosts/<platform>/<name>, and each one is a
      # small data file rather than a hand-written system configuration.
      hosts = import ./lib/hosts.nix { inherit lib profiles vars; };

      configurations = import ./lib/configurations.nix {
        inherit
          lib
          vars
          profiles
          hosts
          ;
        inputs = {
          inherit
            nixpkgs
            nixos-hardware
            disko
            preservation
            home-manager
            nix-darwin
            ;
        };
      };

      forEachSystem = lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      inherit (configurations) nixosConfigurations darwinConfigurations;

      formatter = forEachSystem (
        system:
        nixpkgs.legacyPackages.${system}.nixfmt-tree.override {
          nixfmtPackage = nixpkgs.legacyPackages.${system}.nixfmt-rs;
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              deadnix
              just
              nixfmt-rs
            ];
          };
        }
      );
    };
}
