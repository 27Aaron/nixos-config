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
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
    optimise.automatic = true;
    settings = {
      builders-use-substitutes = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://cache.soopy.moe"
        "https://cache.numtide.com"
      ];
      extra-trusted-public-keys = [
        "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
      trusted-users = [ vars.username ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs.nh = {
    enable = true;
    flake = lib.mkDefault "/home/aaron/nixos-config";
  };

  # nh 讀取的配置倉庫目錄。
  preservation'.user.directories = [
    {
      directory = "nixos-config";
      mode = "0700";
    }
  ];
}
