{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.fish = {
    enable = true;
    useBabelfish = true;
    interactiveShellInit = ''
      fish_vi_key_bindings
    '';
  };

  # 主要使用者的登入 shell。
  user'.shell = pkgs.fish;

  # fish 的設定與歷史。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".config/fish"
    {
      directory = ".local/share/fish";
      mode = "0700";
    }
  ];
}
