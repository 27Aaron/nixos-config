# fish 作為主要使用者的登入 shell,NixOS 與 nix-darwin 共用。
{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    useBabelfish = true;
    interactiveShellInit = ''
      fish_vi_key_bindings
    '';
  };

  user'.shell = pkgs.fish;
}
