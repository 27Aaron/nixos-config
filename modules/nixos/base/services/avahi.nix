{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.avahi;
in
{
  options.services'.avahi = {
    enable = lib.mkEnableOption "Avahi mDNS, publishing this host as <hostName>.local on the LAN";
  };

  config = lib.mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      # mDNS 固定使用 5353/udp,沒有可改的埠。
      openFirewall = true;

      # 讓區網其他機器不必知道 IP,就能以 <hostName>.local 找到這臺。
      publish = {
        enable = true;
        domain = true;
        userServices = true;
      };
    };
  };
}
