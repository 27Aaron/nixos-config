{
  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-UncertainTruth_LX700_U25202KBD1090";
    espSize = "1G";
    swapSize = "65537M";
    luks.enable = true;
    # 不設 PIN,見 WA-022。
    luks.tpm2.enable = true;
  };

  hardware'.persistence.enable = true;

  services' = {
    zram.enable = true;

    smartd.enable = true;
    btrfs-scrub.enable = true;
    btrbk.enable = true;
  };
}
