{ config, lib, ... }:
{
  # 只有 wheel 能連上 nix-daemon;服務帳號即使被攻破,也碰不到 daemon 的
  # 提權類漏洞。root 一律可連線。
  nix.settings.allowed-users = [ "@wheel" ];

  # nh 從固定路徑讀取 flake,倉庫本身須持久化。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
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
