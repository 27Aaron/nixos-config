# MacBook Pro 2023 16-inch (M2 Max, 96 GB RAM, 4 TB SSD)
{
  system = "aarch64-darwin";

  modules = [
    {
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.stateVersion = 6;
    }
  ];
}
