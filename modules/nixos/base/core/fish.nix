{
  # fish 的設定與歷史;登入 shell 由 modules/base/fish.nix 設定。
  preservation'.user.directories = [
    ".config/fish"
    ".local/share/fish"
  ];
}
