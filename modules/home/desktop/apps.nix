{ inputs, pkgs, ... }:
{
  home.packages = [
    pkgs.vscode
    inputs.nagram.packages.${pkgs.stdenv.hostPlatform.system}.nagram-desktop
  ];

  # 設定與登入態由程式自行寫入,只保留跨重啟。
  persist'.directories = [
    # VS Code 的使用者資料、擴充功能與工作區狀態。
    ".config/Code"
    ".vscode"

    # Nagram 的工作階段與設定,含 tdata。沒有舊資料時寫在這裡。
    ".local/share/NagramDesktop"
  ];
}
