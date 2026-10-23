{ config, lib, ... }:
{
  # fish 的設定與歷史;登入 shell 由 modules/base/core/fish.nix 設定。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".config/fish"
    {
      directory = ".local/share/fish";
      mode = "0700";
    }
  ];
}
