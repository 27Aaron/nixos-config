# MacBook Pro 2023 16-inch (M2 Max, 96 GB RAM, 4 TB SSD)
{ ... }:
{
  profiles = {
    darwin = [ "workstation" ];

    home = [
      "common"
      "darwin"
    ];
  };

  system = "aarch64-darwin";
  stateVersion = 6;
}
