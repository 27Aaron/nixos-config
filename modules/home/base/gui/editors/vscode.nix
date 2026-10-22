{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.vscode;
in
{
  options.gui'.vscode.enable = lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide

          # 讓編輯器跟著專案的 .envrc 走。
          arrterian.nix-env-selector
          mkhl.direnv

          catppuccin.catppuccin-vsc
          pkief.material-icon-theme
        ];
      };
    };

    # 設定與登入狀態由程式自行寫入。
    persist'.directories = [
      ".config/Code"
      ".vscode"
      ".vscode-shared"
    ];
  };
}
