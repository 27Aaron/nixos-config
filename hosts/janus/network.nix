{
  networking.nameservers = [ "192.168.2.2" ];

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "192.168.2.1/24" ];
    gateway = [ "192.168.2.2" ];
    networkConfig.DHCP = "ipv6";
  };
}
