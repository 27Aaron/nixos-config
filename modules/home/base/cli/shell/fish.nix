{
  # 登入 shell 與狀態目錄的持久化由 modules/core/fish.nix 設定。
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };
}
