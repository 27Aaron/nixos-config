{
  nix = {
    channel.enable = false;
    optimise.automatic = true;
    settings = {
      builders-use-substitutes = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # 刻意不把主要使用者列入 trusted-users:受信任的使用者可以停用簽章檢查、
      # 匯入任意 store 路徑,等同免密碼取得 root。部署以 root 連入,不需要它;
      # 專案 flake 的 nixConfig 快取會被忽略,需要的快取登記在下方。
      extra-substituters = [
        "https://cache.numtide.com"
        "https://fcitx5-vinput.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
}
