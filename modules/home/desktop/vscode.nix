{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;

    profiles.default = {
      # 清單即聲明:每次切換同步,版本跟著 nixpkgs;未列出的仍可自行安裝。
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

    # 共享狀態:信任清單與最近開啟,不保留則重啟後重新詢問信任。
    ".vscode-shared"
  ];
}
