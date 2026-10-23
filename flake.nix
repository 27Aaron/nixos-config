{
  description = "Aaron's NixOS configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
      # url = "github:NixOS/nixpkgs/nixos-unstable-small";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation = {
      url = "github:nix-community/preservation";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur-packages = {
      url = "github:27Aaron/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fonts = {
      url = "github:27Aaron/Fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nagram = {
      url = "github:NextAlone/Nagram-Qt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fcitx5-vinput = {
      url = "github:xifan2333/fcitx5-vinput/v2.4.2";
    };

    secrets = {
      url = "git+ssh://git@github.com/27Aaron/nix-secrets.git?shallow=1";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rs);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.deadnix
              pkgs.nixfmt-rs
            ];
          };
        }
      );

      inherit (import ./hosts { inherit inputs; }) nixosConfigurations darwinConfigurations;

      checks = forAllSystems (
        system:
        let
          onSystem = nixpkgs.lib.filterAttrs (_: host: host.config.nixpkgs.hostPlatform.system == system);
        in
        {
          eval-tests = import ./tests {
            inherit (nixpkgs) lib;
            pkgs = nixpkgs.legacyPackages.${system};
            nixosConfigurations = onSystem self.nixosConfigurations;
            darwinConfigurations = onSystem self.darwinConfigurations;
          };
        }
      );
    };
}
