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

  user'.shell = pkgs.fish;

  hm'.programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".config/fish"
    {
      directory = ".local/share/fish";
      mode = "0700";
    }
  ];
}
