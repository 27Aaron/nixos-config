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
    enable = lib.mkEnableOption "systemd-boot with EFI variable management";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.hardware'.grub.enable;
        message = "hardware'.systemd-boot and hardware'.grub are mutually exclusive";
      }
    ];

    boot.loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        editor = lib.mkDefault false;
        consoleMode = lib.mkDefault "max";
        configurationLimit = lib.mkDefault 8;
      };
    };
  };
}
