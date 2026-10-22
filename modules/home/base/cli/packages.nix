{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cli'.packages;
in
{
  options.cli'.packages.enable = lib.mkEnableOption "everyday command-line tools";

  config = lib.mkIf cfg.enable {
    # 只安裝、不需設定的命令列工具;需要設定的各自有模組。
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
  };
}
