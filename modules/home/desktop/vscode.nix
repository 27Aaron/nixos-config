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
  ];
}
