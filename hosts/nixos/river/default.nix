{ ... }:

{
  imports = [
    ./hardware.nix
  ];

  core'.firewall.enable = true;
  core'.logging.enable = true;
  core'.sops.enable = true;
  core'.yubikey.enable = true;

  desktop'.greetd.enable = true;
  desktop'.niri.enable = true;
  desktop'.niri.autoLogin = true;
  desktop'.fcitx5.enable = true;
  desktop'.vinput.enable = true;
  desktop'.vinput.lite = true;
  desktop'.noctalia.enable = true;
  desktop'.file-manager.enable = true;
  desktop'.fonts.enable = true;

  services'.dae.enable = true;
  services'.logrotate.enable = true;
  services'.openssh.enable = true;
  services'.networkmanager.enable = true;
  services'.pipewire.enable = true;
  services'.trash.enable = true;
  services'.vnstat.enable = true;
  services'.keyd.enable = true;
  services'.keyd.keyboards = {
    # 內建鍵盤(AT Translated Set 2 keyboard)。
    default = {
      ids = [ "0001:0001" ];
      settings = {
        main = {
          # Copilot 鍵(位於右 Ctrl)送出 meta+shift+F23,整組映射為右 Ctrl。
          "leftshift+leftmeta+f23" = "rightcontrol";
          # keyd 預設把右 Ctrl 轉成左 Ctrl,這裡還原。
          rightcontrol = "rightcontrol";
        };
      };
    };

    # HHKB-Hybrid_2(藍牙):右側 ◇ 鍵送出 rightmeta,映射為右 Ctrl。
    hhkb = {
      ids = [ "04fe:0021" ];
      settings.main = {
        rightmeta = "rightcontrol";
        # keyd 預設把右 Ctrl 轉成左 Ctrl,這裡還原。
        rightcontrol = "rightcontrol";
      };
    };
  };

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "24.11";
}
