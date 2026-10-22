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

    memoryPercent = lib.mkOption {
      type = lib.types.ints.positive;
      default = 50;
      description = "zram swap upper bound, as a percentage of RAM.";
    };

    memoryMax = lib.mkOption {
      type = with lib.types; nullOr int;
      default = null;
      example = 16 * 1024 * 1024 * 1024;
      description = "zram swap upper bound in bytes; the smaller of this and memoryPercent wins.";
    };
  };

  config = lib.mkIf cfg.enable {
    # 停用 zswap(多數核心預設開啟),避免壓縮快取擋在 zram swap 前面。
    # https://wiki.archlinux.org/title/Zram#Usage_as_swap
    boot = {
      kernelParams = [ "zswap.enabled=0" ];

      # 調優配方(Pop!_OS 同款):
      #   https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
      #   https://github.com/pop-os/default-settings/pull/163
      kernel.sysctl = {
        # 記憶體型 swap 的隨機 IO 遠快於檔案系統,可取 100 以上(見 kernel 的 vm 文件)。
        "vm.swappiness" = 180;
        # 關閉 swap 預讀;對壓縮 swap 預讀只是浪費,r/Fedora 實測 0 最佳。
        "vm.page-cluster" = 0;
        # 避免回收後水位提升造成的卡頓尖峰;並讓 kswapd 更早、更平滑地回收。
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
      };

      kernel.sysfs.module.zswap.parameters.enabled = false;
    };

    zramSwap = {
      enable = true;
      # 讓 zram 優先於任何磁碟 swap。
      priority = 100;
      memoryPercent = cfg.memoryPercent;
      memoryMax = cfg.memoryMax;
    };
  };
}
