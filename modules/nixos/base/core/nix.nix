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

  # nh 從固定路徑讀取 flake,因此倉庫本身也要跨重啟保留。
  preservation'.user.directories = [
    {
      directory = "nixos-config";
      mode = "0700";
    }

    # nix 本身的使用者狀態與 profile 連結。
    ".local/share/nix"
    ".local/state/nix/profiles"

    # 快取不含機密但不重建就要重抓 flake input,離線時 nix 直接失敗。
    {
      directory = ".cache/nix";
      mode = "0700";
    }
  ];
}
