{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  time.timeZone = "Asia/Tokyo";

  dev'.claude-code.enable = true;

  services' = {
    avahi.enable = true;

    magpie = {
      enable = true;
      publicUrl = "http://10.10.10.254";
      web = {
        enable = true;
        bind = "10.10.10.254";
        port = 80;
      };
    };

    openssh = {
      enable = true;
      rootLogin = true;
    };

    mihomo-lite = {
      enable = true;
      allowLan = true;
    };
    tailscale.enable = true;

    node-exporter.enable = true;
    vnstat.enable = true;
  };

  system.stateVersion = "26.11";
}
