{
  hardware'.kvm-guest = {
    enable = true;
    diskDevice = "/dev/sda";
    # 1 GB 記憶體的機器,zram 上限跟著壓低,預設的 2049 MiB 對這臺沒意義。
    zramMemoryMax = 513 * 1024 * 1024;
  };

  hardware' = {
    # 這臺的磁碟不加密,也沒有 clevis/Tang 可用;沿用安裝時的
    # systemd-boot 與 ESP,不另外產生 BIOS 開機分割區。
    grub.enable = false;
    systemd-boot.enable = true;
    disko = {
      bios.enable = false;
      luks.enable = false;
    };
  };

  server'.initrd-ssh.enable = false;
}
