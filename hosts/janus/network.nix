{
  # 無螢幕的 VM,用 systemd-networkd 取代 NetworkManager。
  networking = {
    useNetworkd = true;
    useDHCP = false;
  };

  services.resolved.enable = true;

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "192.168.2.1/24" ];
    gateway = [ "192.168.2.2" ];
    dns = [ "192.168.2.2" ];
    networkConfig.DHCP = "ipv6";
  };
}
