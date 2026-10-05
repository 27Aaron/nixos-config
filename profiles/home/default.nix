{
  # Home Manager modules shared by every platform.
  common = [
    ../../modules/home/common/development.nix
    ../../modules/home/common/git.nix
    ../../modules/home/common/kitty.nix
    ../../modules/home/common/persist.nix
    ../../modules/home/common/shell.nix
    ../../modules/home/common/tools.nix
  ];

  # Home Manager modules that depend on nix-darwin options or macOS apps.
  darwin = [
    ../../modules/home/darwin/karabiner.nix
    ../../modules/home/darwin/nh.nix
  ];
}
