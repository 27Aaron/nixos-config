# 終端機介面的監控工具。
#
# btop 與 fastfetch 都是接管整個終端、需要一個已存在的終端才能跑,
# 所以屬於 tui 而不是 core。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    btop
    fastfetch
  ];

  # btop 在 UI 裡調整設定時會自行改寫配置,重開機要留著。
  persist'.directories = [ ".config/btop" ];
}
