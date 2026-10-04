{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.grub;
  diskoCfg = config.hardware'.disko;
in
{
  options.hardware'.grub = {
    enable = lib.mkEnableOption "the GRUB bootloader";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.hardware'.systemd-boot.enable;
        message = "hardware'.grub and hardware'.systemd-boot are mutually exclusive";
      }
    ];

    boot.loader.grub = {
      enable = true;
      efiSupport = lib.mkDefault true;
      efiInstallAsRemovable = lib.mkDefault true;
      configurationLimit = lib.mkDefault 8;
      device = lib.mkDefault (if diskoCfg.bios.enable then diskoCfg.device else "nodev");
      enableCryptodisk = lib.mkIf diskoCfg.luks.enable (lib.mkDefault true);
    };
  };
}
