# 互動式監控工具;一次性輸出的工具在 core。
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

  # btop 會在介面中直接改寫設定檔。
  persist'.directories = [ ".config/btop" ];
}
