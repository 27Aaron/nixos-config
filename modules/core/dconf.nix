{ config, lib, ... }:
{
  # Home Manager 寫入 dconf 需要系統側支援。
  programs.dconf.enable = true;

  # GTK 應用與 Nautilus 執行時寫入的狀態;未以 dconf.settings 宣告,無法由
  # 設定重建。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    {
      directory = ".config/dconf";
      mode = "0700";
    }
  ];
}
