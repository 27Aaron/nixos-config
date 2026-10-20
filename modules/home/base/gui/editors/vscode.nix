{
  pkgs,
  ...
}:
{
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

  # 設定與登入態由程式自己寫入。
  persist'.directories = [
    ".config/Code"
    ".vscode"
    ".vscode-shared"
  ];
}
