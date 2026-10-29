{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.systemd-boot;
in
{
  options.hardware'.systemd-boot = {
    enable = lib.mkEnableOption "systemd-boot bootloader with EFI variable management";
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;
        editor = lib.mkDefault false;
        consoleMode = lib.mkDefault "max";
        configurationLimit = lib.mkDefault 8;
      };

      efi.canTouchEfiVariables = true;
    };
  };
}
