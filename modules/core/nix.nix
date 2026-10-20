{
  lib,
  pkgs,
  vars,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    deadnix
    nixd
    nixfmt-rs
  ];

  nix = {
    channel.enable = false;
    optimise.automatic = true;
    settings = {
      builders-use-substitutes = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ vars.username ];

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

  programs.nh = {
    enable = true;
    flake = lib.mkDefault "/home/${vars.username}/nixos-config";

    # 週期清理取代 nix.gc;兩者同開會觸發 nh 模組的衝突警告。
    clean = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault "--keep 8 --keep-since 14d";
    };
  };

  # nh 讀取的配置倉庫目錄。
  preservation'.user.directories = [
    {
      directory = "nixos-config";
      mode = "0700";
    }

    # Nix 的求值快取、flake 抓取快取與 tarball 快取。這三個不含機密,
    # 但重建需要重新解析並下載 flake input,開機後第一次執行 nix 指令
    # 會因此變慢,且在離線時直接失敗。其餘 ~/.cache 內容留在 tmpfs。
    {
      directory = ".cache/nix";
      mode = "0700";
    }
  ];
}
