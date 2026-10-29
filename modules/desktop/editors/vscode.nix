{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.vscode;
in
{
  options.desktop'.vscode.enable = lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable {
    hm'.programs.vscode = {
      enable = true;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide

          arrterian.nix-env-selector
          mkhl.direnv

          catppuccin.catppuccin-vsc
          pkief.material-icon-theme
        ];
      };
    };

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".config/Code";
        mode = "0700";
      }
      ".vscode"
      ".vscode-shared"
    ];
  };
}
