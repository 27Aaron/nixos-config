{ ... }:
{
  networking = {
    enableIPv6 = false;
    nameservers = [ "10.10.10.1" ];
  };

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "10.10.10.254/24" ];
    networkConfig = {
      IPv6AcceptRA = false;
      LinkLocalAddressing = "no";
    };
    routes = [
      {
        Destination = "0.0.0.0/0";
        Gateway = "10.10.10.1";
      }
    ];
  };
}
