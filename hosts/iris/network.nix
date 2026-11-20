{ ... }:
{
  networking = {
    nameservers = [
      "223.5.5.5"
      "119.29.29.29"
    ];
  };

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "10.10.10.9/24" ];
    networkConfig.DHCP = "ipv6";
    routes = [
      {
        Destination = "0.0.0.0/0";
        Gateway = "10.10.10.1";
      }
    ];
  };
}
