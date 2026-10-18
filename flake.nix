{
  description = "Aaron's NixOS configuration";

  inputs = {
    nixpkgs = {
      # url = "github:NixOS/nixpkgs/nixos-unstable";
      url = "github:NixOS/nixpkgs/nixos-unstable-small";
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
    };

    nagram = {
      url = "github:NextAlone/Nagram-Qt";
    };

    secrets = {
      url = "git+ssh://git@github.com/27Aaron/nix-secrets.git?shallow=1";
      flake = false;
    };
  };

  outputs =
    inputs@{
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

      nixosConfigurations = import ./hosts {
        inputs = inputs;
        nixpkgs = inputs.nixpkgs;
        disko = inputs.disko;
        preservation = inputs.preservation;
        home-manager = inputs.home-manager;
        sops-nix = inputs.sops-nix;
      };
    };
}
