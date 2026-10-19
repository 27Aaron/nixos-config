{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.vscode ];

  # 設定與登入態由程式自行寫入,只保留跨重啟。
  persist'.directories = [
    # 使用者設定、工作區狀態與登入態。
    ".config/Code"

    # 擴充功能。
    ".vscode"

    # 新版 Code 的共享狀態:信任清單與最近開啟清單都在這裡。
    # 沒有它,每次重啟後都會忘記已信任的工作區,重新跳出信任確認。
    ".vscode-shared"
  ];
}
