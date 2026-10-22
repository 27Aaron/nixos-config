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

    # 以 nh 的定期清理取代 nix.gc,兩者同時啟用會觸發警告。
    clean = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault "--keep 8 --keep-since 14d";
    };
  };

  # nh 從固定路徑讀取 flake,倉庫本身須持久化。
  preservation'.user.directories = [
    {
      directory = "nixos-config";
      mode = "0700";
    }

    # nix 的使用者狀態與 profile 連結。
    ".local/share/nix"
    ".local/state/nix/profiles"

    # flake 輸入的快取;遺失後須重新下載,離線時無法求值。
    {
      directory = ".cache/nix";
      mode = "0700";
    }
  ];
}
