# 磁碟、持久化與儲存維護。
{
  # 磁碟與檔案系統佈局(ESP、LUKS、Btrfs、swapfile)。
  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_24364AD5D8E0";
    espSize = "1G";
    swapSize = "32769M";
    luks.enable = true;
    luks.fido2.enable = true;
  };

  # 狀態持久化。
  hardware'.persistence.enable = true;

  services' = {
    # 壓縮 swap,上限 16G(記憶體不足 16G 時則用滿記憶體)。
    zram = {
      enable = true;
      memoryPercent = 100;
      memoryMax = 16 * 1024 * 1024 * 1024;
    };

    # 磁碟健康與 Btrfs 維護。
    smartd.enable = true;
    btrfs-scrub.enable = true;
    btrbk.enable = true;
  };
}
