{
  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_24364AD5D8E0";
    espSize = "1G";
    swapSize = "32769M";
    games.enable = true;
    luks.enable = true;
    # 不設 PIN,見 WA-023。
    luks.tpm2.enable = true;
  };

  hardware'.persistence.enable = true;

  services' = {
    zram = {
      enable = true;
      memoryPercent = 100;
      memoryMax = 16 * 1024 * 1024 * 1024;
    };

    smartd.enable = true;
    btrfs-scrub.enable = true;
    btrbk.enable = true;
  };
}
