{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.pipewire;
in
{
  options.services'.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio stack";
  };

  config = {
    services.pipewire = lib.mkIf cfg.enable {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # 讓音訊伺服器透過 RTKit 請求即時排程。
    security.rtkit.enable = lib.mkIf cfg.enable true;

    # 上游消費者可能自行啟用此堆疊,持久化跟隨服務的最終狀態,
    # 無論是誰開啟的。
    preservation'.user.directories = lib.optionals config.services.pipewire.enable [
      # PulseAudio 相容性 cookie
      {
        directory = ".config/pulse";
        mode = "0700";
      }
      # WirePlumber 儲存的路由與設備
      {
        directory = ".local/state/wireplumber";
        mode = "0700";
      }
    ];
  };
}
