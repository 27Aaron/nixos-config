# 命令列工具:讀入、輸出、結束,自己不畫介面。
#
# 這一類只安裝程式,不做任何設定。真正需要配置的工具各自有模組,
# 例如 shell.nix、git.nix、development.nix。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # 磁碟用量。
    dust
    duf
    ncdu

    # 搜尋、文字處理與導航。
    fd
    fzf
    gawk
    gnugrep
    gnused
    jq
    ripgrep

    # 建置工具。
    just

    # 網路與診斷。
    curl
    iperf3
    nload
    nmap
    socat
    wget
  ];
}
