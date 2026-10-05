{ pkgs, ... }:
{
  imports = [
    ../common/nix.nix
    ./defaults.nix
    ./homebrew.nix
    ./host.nix
  ];

  # Make fish a valid login shell in /etc/shells.
  environment.shells = [ pkgs.fish ];
}
