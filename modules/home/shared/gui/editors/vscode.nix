{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.vscode;
in
{
  options.gui.vscode.enable = lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
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

    persist.directories = lib.mkIf config.persist.enable [
      {
        directory = ".config/Code";
        mode = "0700";
      }
      ".vscode"
      ".vscode-shared"
    ];
  };
}
