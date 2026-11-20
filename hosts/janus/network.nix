{
  # 無螢幕的 VM,kvm-guest 基線已啟用 networkd 並關閉 resolved;系統解析器
  # 直接指向上游,不經過 stub-resolved。
  networking.nameservers = [ "192.168.2.2" ];

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "192.168.2.1/24" ];
    gateway = [ "192.168.2.2" ];
    networkConfig.DHCP = "ipv6";
  };
}
