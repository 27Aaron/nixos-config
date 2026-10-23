{
  # 磁碟與檔案系統佈局(ESP、LUKS、Btrfs、swapfile)。
  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-UncertainTruth_LX700_U25202KBD1090";
    espSize = "1G";
    swapSize = "65537M";
    luks.enable = true;
  };

  # 狀態持久化。
  hardware'.persistence.enable = true;

  services' = {
    zram.enable = true;

    # 磁碟健康與 Btrfs 維護。
    smartd.enable = true;
    btrfs-scrub.enable = true;
    btrbk.enable = true;
  };
}
