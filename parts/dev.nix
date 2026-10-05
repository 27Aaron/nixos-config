# Formatter and development shell, driven by treefmt-nix.
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        # Keep formatting identical to before: nixfmt-rs, just through treefmt.
        programs.nixfmt = {
          enable = true;
          package = pkgs.nixfmt-rs;
        };
      };

      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [ config.treefmt.build.devShell ];
        packages = with pkgs; [
          deadnix
          just
        ];
      };
    };
}
