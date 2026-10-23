{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    ncdu
    nload
  ];

  # btop 會在介面中直接改寫設定檔。
  persist'.directories = [ ".config/btop" ];
}
