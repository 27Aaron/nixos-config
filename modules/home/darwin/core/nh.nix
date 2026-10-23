{ config, ... }:
{
  # nix-darwin 沒有 programs.nh 模組,改由 Home Manager 啟用。
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/nixos-config";
  };
}
