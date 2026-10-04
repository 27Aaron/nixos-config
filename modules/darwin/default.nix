{ pkgs, ... }:
{
  imports = [
    ../common/nix.nix
    ./defaults.nix
    ./homebrew.nix
  ];

  # Use Fish as the login shell.
  programs.fish.enable = true;

  user'.shell = pkgs.fish;
  environment.shells = [ pkgs.fish ];
}
