# Seahorse:檢視與管理 GNOME 鑰匙環,開自己的視窗。
{ pkgs, ... }:
{
  home.packages = [ pkgs.seahorse ];

  # Seahorse 直接操作鑰匙環本身;~/.local/share/keyrings 由
  # nixos/base/hardware/persistence.nix 統一登記,這裡不重複。
}
