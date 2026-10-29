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

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".config/fish"
    {
      directory = ".local/share/fish";
      mode = "0700";
    }
  ];
}
