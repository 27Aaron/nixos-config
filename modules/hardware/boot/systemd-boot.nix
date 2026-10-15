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

      # bootctl 會在安裝時註冊「Linux Boot Manager」NVRAM 項目;
      # 正是這個共享的 EFI 層選項允許它這麼做。
      efi.canTouchEfiVariables = true;
    };
  };
}
