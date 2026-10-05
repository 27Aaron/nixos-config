{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # System information and monitoring.
    btop
    fastfetch

    # Disk usage.
    dust
    duf
    ncdu

    # Search, text processing, and navigation.
    fd
    fzf
    gawk
    gnugrep
    gnused
    jq
    ripgrep

    # Development and version control.
    git
    git-lfs
    just
    neovim

    # Networking and diagnostics.
    curl
    iperf3
    nload
    nmap
    socat
    wget
  ];
}
