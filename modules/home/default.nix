# 平臺入口。modules/default.nix 遇到帶 default.nix 的目錄就停止遞迴,所以
# 整個 modules/home/ 只有在這裡明確列出才會載入;darwin 主機把 ./nixos 換
# 成 ./darwin 即可,共用的 base 不必改。
{
  vars,
  ...
}:
{
  # Home Manager 寫入 dconf 需要系統側支援。
  programs.dconf.enable = true;

  home-manager.users.${vars.username}.imports = [
    ./base
    ./nixos
  ];

  # Home Manager 自己的狀態。
  preservation'.user.directories = [ ".local/state/home-manager" ];
}
