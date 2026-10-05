{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    alejandra
    deadnix
    nixd
  ];

  nix = {
    channel.enable = false;
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
    optimise.automatic = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      builders-use-substitutes = true;
      extra-substituters = [
        "https://cache.soopy.moe"
        "https://cache.numtide.com"
      ];
      extra-trusted-public-keys = [
        "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
}
