{ pkgs, ... }:
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
}
