{
  # 直接使用上游的 services.keyd;它的選項已經夠用,不另外包一層。
  services.keyd.enable = true;
  services.keyd.keyboards = {
    # 內建鍵盤(AT Translated Set 2 keyboard)。
    default = {
      ids = [ "0001:0001" ];
      settings = {
        main = {
          # Copilot 鍵(位於右 Ctrl)送出 meta+shift+F23,整組映射為右 Ctrl。
          "leftshift+leftmeta+f23" = "rightcontrol";
          # keyd 預設把右 Ctrl 轉成左 Ctrl,這裡還原;見 WA-008。
          rightcontrol = "rightcontrol";
        };
      };
    };

    # HHKB-Hybrid_2(藍牙):右側 ◇ 鍵送出 rightmeta,映射為右 Ctrl。
    hhkb = {
      ids = [ "04fe:0021" ];
      settings.main = {
        rightmeta = "rightcontrol";
        # keyd 預設把右 Ctrl 轉成左 Ctrl,這裡還原;見 WA-008。
        rightcontrol = "rightcontrol";
      };
    };

    # Razer Orochi V2(接收器):前側鍵複製、後側鍵貼上。
    # 接收器另外宣告了一個同 ID 的鍵盤介面,用 m: 只比對滑鼠。
    orochi = {
      ids = [ "m:1532:0094" ];
      settings.main = {
        mouse2 = "C-c";
        mouse1 = "C-v";
      };
    };
  };
}
