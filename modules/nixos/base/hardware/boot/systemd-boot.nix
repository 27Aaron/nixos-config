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

      # bootctl 安裝時要註冊 NVRAM 項目,少了這個共享的 EFI 層選項就會失敗。
      efi.canTouchEfiVariables = true;
    };
  };
}
