{ ... }:
{
  modules = [
    ./hardware.nix

    {
      security'.firewall.enable = true;

      services' = {
        networkmanager.enable = true;
        openssh.enable = true;
        vnstat.enable = true;
      };
    }
  ];

  timeZone = "Asia/Tokyo";

  profiles = {
    nixos = [
      "server"
      "desktop"
      "ephemeral-root"
    ];

    home = [ "common" ];
  };

  system = "x86_64-linux";
  stateVersion = "26.05";
}
