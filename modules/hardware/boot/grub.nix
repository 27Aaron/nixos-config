{
  config,
  lib,
  ...
}:
let
  cfg = config.hardware'.grub;
in
{
  options.hardware'.grub = {
    enable = lib.mkEnableOption ''
      GRUB installed as a removable EFI bootloader, for firmware whose EFI
      variables cannot be trusted to keep the entries systemd-boot writes
    '';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.boot.loader.systemd-boot.enable;
        message = "hardware'.grub replaces systemd-boot; disable hardware'.systemd-boot.";
      }
      {
        assertion = !config.hardware'.lanzaboote.enable;
        message = "hardware'.grub and hardware'.lanzaboote are exclusive bootloaders.";
      }
    ];

    # GRUB 裝在 ESP 的預設路徑,韌體遺失 NVRAM 啟動項時仍能開機。
    boot.loader = {
      timeout = lib.mkDefault 2;
      grub = {
        enable = true;
        device = lib.mkDefault "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
        configurationLimit = lib.mkDefault 5;
      };
    };
  };
}
