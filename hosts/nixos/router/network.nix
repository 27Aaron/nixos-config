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
    address = [ "10.10.10.11/24" ];
    gateway = [ "10.10.10.1" ];
    dns = [ "10.10.10.1" ];
    networkConfig.DHCP = "ipv6";
  };
}
