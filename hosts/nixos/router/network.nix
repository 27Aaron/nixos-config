{ ... }:
{
  # Headless VM: systemd-networkd instead of NetworkManager.
  networking = {
    useNetworkd = true;
    useDHCP = false;
  };

  services.resolved.enable = true;

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    # IPv4 comes from the static address; IPv6 addresses and routes are
    # obtained through DHCPv6 and router advertisements.
    address = [ "192.168.2.1/24" ];
    gateway = [ "192.168.2.2" ];
    dns = [ "192.168.2.2" ];
    networkConfig.DHCP = "ipv6";
  };
}
