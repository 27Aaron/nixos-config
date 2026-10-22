{
  # 以 nftables 實作防火牆,開放的連接埠由各服務模組自行登記。
  networking = {
    firewall.enable = true;
    nftables.enable = true;
  };
}
