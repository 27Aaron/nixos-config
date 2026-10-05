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
    enable = lib.mkEnableOption "Disable virtio_balloon module";
  };

  config = lib.mkIf cfg.enable {
    boot.extraModprobeConfig = ''
      blacklist virtio_balloon
      install virtio_balloon ${pkgs.coreutils}/bin/true
    '';
  };
}
