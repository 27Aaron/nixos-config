{
  # Home Manager modules shared by every platform.
  common = [
    ../../modules/home/common/development.nix
    ../../modules/home/common/git.nix
    ../../modules/home/common/kitty.nix
    ../../modules/home/common/shell.nix
    ../../modules/home/common/tools.nix
  ];

  # Home Manager modules that depend on nix-darwin options or macOS apps.
  darwin = [
    ../../modules/home/darwin/karabiner.nix
    ../../modules/home/darwin/nh.nix
  ];

  # Home Manager modules for a graphical desktop session: appearance and the
  # user-facing applications. Mirrors the `desktop` role on the NixOS axis.
  desktop = [
    ../../modules/home/nixos/cursors.nix
    ../../modules/home/nixos/firefox.nix
    ../../modules/home/nixos/google-chrome.nix
    ../../modules/home/nixos/telegram.nix
    ../../modules/home/nixos/themes.nix
    ../../modules/home/nixos/vscode.nix
  ];
}
