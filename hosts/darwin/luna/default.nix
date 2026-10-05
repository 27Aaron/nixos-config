# MacBook Pro 2023 16-inch (M2 Max, 96 GB RAM, 4 TB SSD)
{ profiles, ... }:
{
  system = "aarch64-darwin";
  stateVersion = 6;

  profiles = {
    darwin = with profiles.darwin; [ workstation ];

    home = with profiles.home; [
      common
      darwin
    ];
  };
}
