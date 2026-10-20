# 互動式監控工具,需要一個已存在的終端;一次印完就退出的工具在 core。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    btop
    ncdu
    nload
  ];

  # btop 在 UI 裡改設定時會自行改寫配置。
  persist'.directories = [ ".config/btop" ];
}
