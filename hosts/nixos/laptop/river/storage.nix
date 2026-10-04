{
  hardware'.disko = {
    enable = true;
    device = "/dev/nvme0n1";
    espSize = "512M";
    swapSize = "16385M";
    tmpfsSize = "2G";
  };

  hardware'.persistence.enable = true;
}
