{
  # 登入 shell 由 modules/base/core/fish.nix 設定,狀態目錄由
  # modules/nixos/base/core/fish.nix 持久化。
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };
}
