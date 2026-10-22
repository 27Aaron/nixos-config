# Home Manager 的平臺入口。modules/default.nix 遇到含 default.nix 的目錄
# 即停止遞迴,因此 modules/home/ 只經由這裡載入;darwin 主機改匯入 ./darwin。
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
