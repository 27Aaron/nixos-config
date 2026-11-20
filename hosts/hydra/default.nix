{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  time.timeZone = "Asia/Tokyo";

  dev'.claude-code.enable = true;

  services'.magpie = {
    enable = true;
    publicUrl = "http://10.10.10.254";
    web = {
      enable = true;
      bind = "10.10.10.254";
      port = 80;
    };
  };

  services' = {
    avahi.enable = true;

    openssh.enable = true;

    dae.enable = true;
    tailscale.enable = true;

    node-exporter.enable = true;
    vnstat.enable = true;
  };

  system.stateVersion = "26.11";
}
