# 只安裝、不配置的命令列工具;需要配置的各自有模組。
# 互動式的 ncdu 與 nload 屬 tui,不在這裡。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fastfetch

    dust
    duf

    fd
    fzf
    gawk
    gnugrep
    gnused
    jq
    ripgrep

    just

    curl
    iperf3
    nmap
    socat
    wget
  ];
}
