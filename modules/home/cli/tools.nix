{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # 系統資訊與監控。
    btop
    fastfetch

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

    # 開發與版本控制。
    git
    git-lfs
    just

    # 網路與診斷。
    curl
    iperf3
    nload
    nmap
    socat
    wget
  ];

  # 會自行改寫配置的工具。
  persist'.directories = [
    # btop 在 UI 裡調整設定時會自行改寫配置。
    ".config/btop"
  ];
}
