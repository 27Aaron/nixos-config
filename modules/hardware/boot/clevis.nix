{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.clevis;
in
{
  options.hardware'.clevis = {
    enable = lib.mkEnableOption "LUKS auto-unlock through Clevis and Tang";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.hardware'.disko.luks.enable;
        message = "hardware'.clevis needs the encrypted partition from hardware'.disko.";
      }
    ];

    environment.systemPackages = [ pkgs.clevis ];

    # 綁定寫在 LUKS header,這裡只把解鎖放進 initrd;Tang 連不上時仍可手動輸入密碼。
    boot.initrd.clevisLuksAskpass = {
      enable = true;
      useTang = true;
    };

    # NixOS 會再給 systemd 打一個 patch,store path 和 clevis 編譯時用的不同。
    # askpass 寫死的是後者,補進 initrd。
    boot.initrd.systemd.storePaths = [ "${pkgs.systemd}/lib/systemd/systemd-reply-password" ];
  };
}
