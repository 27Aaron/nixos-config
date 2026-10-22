{
  # fish 的設定與歷史;登入 shell 由 modules/base/core/fish.nix 設定。
  preservation'.user.directories = [
    ".config/fish"
    {
      directory = ".local/share/fish";
      mode = "0700";
    }
  ];
}
