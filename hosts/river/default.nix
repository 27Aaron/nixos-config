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
  services'.openssh.enable = true;
  services'.networkmanager.enable = true;
  services'.pipewire.enable = true;
  services'.vnstat.enable = true;
  services'.keyd.enable = true;
  services'.keyd.keyboards = {
    # 僅套用於內建「AT Translated Set 2 keyboard」(vendor:product)。
    # 其餘裝置(Razer 滑鼠)不受影響。
    default = {
      ids = [ "0001:0001" ];
      settings = {
        main = {
          # Copilot 鍵位於右 Ctrl 的位置,按下時會以單次釋放送出
          # meta+shift+F23,因此需將整組按鍵組合一起映射。
          "leftshift+leftmeta+f23" = "rightcontrol";
          # 還原 keyd 預設將右 Ctrl 改送左 Ctrl 的行為。
          rightcontrol = "rightcontrol";
        };
      };
    };

    # HHKB-Hybrid_2(藍牙):右側 ◇(mod)鍵預設送出 rightmeta
    # (右 Win 鍵),將其映射為 rightcontrol。
    hhkb = {
      ids = [ "04fe:0021" ];
      settings.main = {
        rightmeta = "rightcontrol";
        # 還原 keyd 預設將右 Ctrl 改送左 Ctrl 的行為。
        rightcontrol = "rightcontrol";
      };
    };
  };

  time.timeZone = "Asia/Tokyo";
  system.stateVersion = "24.11";
}
