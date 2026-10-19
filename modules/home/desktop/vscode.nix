{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;

    profiles.default = {
      # 安裝清單即聲明:每次切換同步成這份清單,版本跟著 nixpkgs 走;
      # 未列出的擴充功能仍可在編輯器裡自行安裝。
      extensions = with pkgs.vscode-extensions; [
        # Nix 語言支援:語法、格式化與 LSP。
        jnoortheen.nix-ide

        # 開發環境:擴充功能宿主與語言伺服器跟著 .envrc 走。
        arrterian.nix-env-selector
        mkhl.direnv

        # 佈景主題與圖示。
        catppuccin.catppuccin-vsc
        pkief.material-icon-theme
      ];
    };
  };

  # 設定與登入態由程式自行寫入,只保留跨重啟。
  # userSettings 未宣告,settings.json 不會被 Home Manager 碰。
  persist'.directories = [
    # 使用者設定、工作區狀態與登入態。
    ".config/Code"

    # 擴充功能(programs.vscode 也安裝在這裡)。
    ".vscode"

    # 新版 Code 的共享狀態:信任清單與最近開啟清單都在這裡。
    # 沒有它,每次重啟後都會忘記已信任的工作區,重新跳出信任確認。
    ".vscode-shared"
  ];
}
