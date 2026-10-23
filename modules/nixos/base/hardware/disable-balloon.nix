{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.disable-balloon;
in
{
  options.hardware'.disable-balloon = {
    enable = lib.mkEnableOption "blocking the virtio balloon driver";
  };

  # 宿主機透過 balloon 回收記憶體時,會讓記憶體本來就少的 VM 不夠用。
  # 只靠 blacklist 擋不住明確的 modprobe,要同時有 install 規則。
  config = lib.mkIf cfg.enable {
    boot.blacklistedKernelModules = [ "virtio_balloon" ];
    boot.extraModprobeConfig = ''
      install virtio_balloon ${pkgs.coreutils}/bin/true
    '';
  };
}
