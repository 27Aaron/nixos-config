{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.zram;
in
{
  options.services'.zram = {
    enable = lib.mkEnableOption "compressed RAM swap with Zram";
  };

  config = lib.mkIf cfg.enable {
    # 停用 zswap(多數核心預設開啟),避免壓縮快取擋在
    # 壓縮的 Zram swap 裝置前面。
    boot = {
      kernelParams = [ "zswap.enabled=0" ];
      kernel.sysctl."vm.swappiness" = 100;
      kernel.sysfs.module.zswap.parameters.enabled = false;
    };

    zramSwap = {
      enable = true;
      # 讓 Zram 裝置的優先級高於任何磁碟 swap。
      priority = 100;
    };
  };
}
