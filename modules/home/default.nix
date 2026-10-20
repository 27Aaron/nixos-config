# 平台入口:决定这台机器属于哪个平台。
#
# modules/default.nix 遇到带 default.nix 的目录就停止递归,所以整个
# modules/home/ 只有在這裡被明確列出才會載入。NixOS 主機引 base 與 nixos;
# 日後 darwin 主機把 ./nixos 換成 ./darwin,共用的 base 不必改。
{
  vars,
  ...
}:
{
  # Home Manager 寫入 dconf 需要系統側的 dconf 支援。
  programs.dconf.enable = true;

  home-manager.users.${vars.username}.imports = [
    ./base
    ./nixos
  ];
}
