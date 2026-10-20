{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.seahorse ];

  # 鑰匙環本身由 nixos/base/hardware/persistence.nix 登記,這裡不重複。
}
