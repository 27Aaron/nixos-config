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
    # 系統資訊:印完就退出,不接管畫面。
    fastfetch

    # 磁碟用量:duf 與 dust 都是一次性輸出;互動式的 ncdu 在 tui/monitoring.nix。
    dust
    duf

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

    # 網路與診斷。互動式的 nload 在 tui/monitoring.nix。
    curl
    iperf3
    nmap
    socat
    wget
  ];
}
