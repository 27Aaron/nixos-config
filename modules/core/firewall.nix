{
  # 連接埠由各服務模組自行開放。
  networking = {
    firewall.enable = true;
    nftables.enable = true;
  };
}
