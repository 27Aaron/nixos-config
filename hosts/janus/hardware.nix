{
  hardware'.kvm-guest = {
    enable = true;
    diskDevice = "/dev/sda";
    # 1 GB 記憶體的機器,zram 上限跟著壓低,預設的 2049 MiB 對這臺沒意義。
    zramMemoryMax = 513 * 1024 * 1024;
  };
}
