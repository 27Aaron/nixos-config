{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.btrfs-scrub;
in
{
  options.services'.btrfs-scrub = {
    enable = lib.mkEnableOption "monthly Btrfs data scrubbing";
  };

  config = lib.mkIf cfg.enable {
    services.btrfs.autoScrub = {
      enable = true;
      # 每月 1 日 04:00,避開 btrbk 在 00:00/12:00 的快照
      # 時段,讓長時間的 scrub 不與備份重疊。
      interval = "*-*-01 04:00:00";
    };
  };
}
