{ config, lib, ... }:
{
  # kvm-guest 基線已啟用 networkd 並關閉 resolved;系統解析器直接指向上游。
  networking.nameservers = [ "192.168.2.2" ];

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "192.168.2.1/24" ];
    gateway = [ "192.168.2.2" ];
    networkConfig.DHCP = "ipv6";
  };

  # initrd 裡也要有網路,initrd-ssh 才能遠端解鎖 LUKS。
  boot.initrd.systemd.network = lib.mkIf config.server'.initrd-ssh.enable {
    networks."10-eth0" = {
      matchConfig.Name = "eth0";
      address = [ "192.168.2.1/24" ];
      gateway = [ "192.168.2.2" ];
      networkConfig = {
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
