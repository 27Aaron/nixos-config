# 互動式的終端監控工具:會一直停在畫面上等按鍵,需要一個已存在的終端。
#
# 一次印完就退出的工具(fastfetch、duf、dust)屬於 core,不在這裡。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # 資源與磁碟監控;ncdu 是 ncurses 介面,按鍵操作。
    btop
    ncdu

    # 網路流量;ncurses 圖表。
    nload
  ];

  # btop 在 UI 裡調整設定時會自行改寫配置,重開機要留著。
  persist'.directories = [ ".config/btop" ];
}
