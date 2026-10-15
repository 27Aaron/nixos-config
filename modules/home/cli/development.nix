{
  # 以 direnv 與 nix-direnv 載入專案環境。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # 啟用 mise,但不在這裡管理它的全域工具版本。
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # 透過 Home Manager 安裝 uv。
  programs.uv.enable = true;

  # 上述工具的執行時狀態:direnv 的 .envrc 允許清單、
  # mise 管理的工具鏈,以及 uv 管理的直譯器與工具。
  persist'.directories = [
    ".local/share/direnv"
    ".local/share/mise"
    ".local/share/uv"
  ];
}
