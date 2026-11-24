{
  hardware'.kvm-guest = {
    enable = true;
    disk.enable = true;
    # 1 GB 記憶體壓低 zram 上限,預設的 2049 MiB 對這臺沒意義。
    zramMemoryMax = 513 * 1024 * 1024;
  };
}
