{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    useBabelfish = true;
    # 僅互動式 shell 載入 vi 按鍵綁定,避免影響腳本與非互動執行。
    interactiveShellInit = ''
      fish_vi_key_bindings
    '';
  };

  user'.shell = pkgs.fish;

  preservation'.user.directories = [
    ".config/fish"
    ".local/share/fish"
  ];
}
