{ config, lib, ... }:
let
  cfg = config.services'.zram;
in
{
  options.services'.zram = {
    enable = lib.mkEnableOption "zram compressed swap";
  };

  config = lib.mkIf cfg.enable {
    # Disable zswap (on by default in most kernels) so no compressed cache
    # sits in front of the compressed Zram swap device.
    boot = {
      kernelParams = [ "zswap.enabled=0" ];
      kernel.sysctl."vm.swappiness" = 100;
      kernel.sysfs.module.zswap.parameters.enabled = false;
    };

    zramSwap = {
      enable = true;
      # Keep the Zram device ahead of any disk-backed swap.
      priority = 100;
    };
  };
}
