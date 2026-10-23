{ pkgs, ... }:
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
