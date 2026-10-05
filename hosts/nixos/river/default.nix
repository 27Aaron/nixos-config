{ profiles, ... }:
{
  system = "x86_64-linux";
  stateVersion = "26.05";
  timeZone = "Asia/Tokyo";

  profiles = {
    nixos = with profiles.nixos; [
      server
      desktop
      ephemeral-root
    ];

    home = with profiles.home; [ common ];
  };

  modules = [
    ./hardware.nix

    # What this machine runs. The profiles only bring the modules in; the
    # switches are a per-host decision.
    {
      security'.firewall.enable = true;

      services' = {
        networkmanager.enable = true;
        openssh.enable = true;
        vnstat.enable = true;
      };
    }
  ];
}
