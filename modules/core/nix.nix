{
  config,
  lib,
  vars,
  ...
}:
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
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

      # 只有 wheel 能連上 nix-daemon;服務帳號即使被攻破,也碰不到 daemon 的
      # 提權類漏洞。root 一律可連線。
      allowed-users = [ "@wheel" ];
    };
  };

  programs.nh = {
    enable = true;
    flake = lib.mkDefault "${config.users.users.${vars.username}.home}/nixos-config";

    # 以 nh 的定期清理取代 nix.gc,兩者同時啟用會觸發警告。
    clean = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault "--keep 8 --keep-since 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # nh 從固定路徑讀取 flake,倉庫本身須持久化。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    {
      directory = "nixos-config";
      mode = "0700";
    }

    ".local/share/nix"
    ".local/state/nix/profiles"

    # flake 輸入的快取;遺失後須重新下載,離線時無法求值。
    {
      directory = ".cache/nix";
      mode = "0700";
    }
  ];
}
