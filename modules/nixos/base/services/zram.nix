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
      description = ''
        Maximum total amount of memory usable by the zram swap devices,
        as a percentage of total RAM.
      '';
    };

    memoryMax = lib.mkOption {
      type = with lib.types; nullOr int;
      default = null;
      example = 16 * 1024 * 1024 * 1024;
      description = ''
        Maximum total amount of memory (in bytes) usable by the zram swap
        devices. The smaller of this and memoryPercent is used.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # 停用 zswap(多數核心預設開啟),避免壓縮快取擋在
    # 壓縮的 Zram swap 裝置前面。
    # https://wiki.archlinux.org/title/Zram#Usage_as_swap
    boot = {
      kernelParams = [ "zswap.enabled=0" ];

      # zram 調優配方,來源(Pop!_OS 同款):
      #   https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
      #   https://github.com/pop-os/default-settings/pull/163
      kernel.sysctl = {
        # 內核文檔:記憶體型 swap 隨機 IO 遠快於檔案系統時可取 100+
        # https://docs.kernel.org/admin-guide/sysctl/vm.html
        "vm.swappiness" = 180;
        # 關閉 swap 預讀;記憶體內壓縮 swap 預讀只是浪費,r/Fedora 實測 0 最優
        "vm.page-cluster" = 0;
        # 避免回收後水位提升造成的卡頓尖峰
        "vm.watermark_boost_factor" = 0;
        # 讓 kswapd 更早、更平滑地背景回收
        "vm.watermark_scale_factor" = 125;
      };

      kernel.sysfs.module.zswap.parameters.enabled = false;
    };

    zramSwap = {
      enable = true;
      # 讓 Zram 裝置的優先級高於任何磁碟 swap。
      priority = 100;
      memoryPercent = cfg.memoryPercent;
      memoryMax = cfg.memoryMax;
    };
  };
}
