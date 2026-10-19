{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Nix 語言支援。
        jnoortheen.nix-ide

        # 開發環境:跟著 .envrc 走。
        arrterian.nix-env-selector
        mkhl.direnv

        # 佈景主題與圖示。
        catppuccin.catppuccin-vsc
        pkief.material-icon-theme
      ];
    };
  };

  # 設定與登入態由程式自行寫入,只保留跨重啟。
  persist'.directories = [
    ".config/Code"
    ".vscode"
    ".vscode-shared"
  ];
}
