{
  # 無螢幕的 VM,用 systemd-networkd 取代 NetworkManager。
  networking = {
    useNetworkd = true;
    useDHCP = false;
  };

  services.resolved.enable = true;

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    # IPv4 用固定位址;IPv6 位址與路由由 DHCPv6 和路由器通告取得。
    address = [ "10.77.77.66/24" ];
    gateway = [ "10.77.77.1" ];
    dns = [ "10.77.77.1" ];
    networkConfig.DHCP = "ipv6";
  };
}
