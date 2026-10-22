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

    # 讓音訊伺服器透過 RTKit 取得即時排程。
    security.rtkit.enable = lib.mkIf cfg.enable true;

    # 依服務的最終狀態而非本模組開關,上游模組也可能啟用它。
    preservation'.user.directories = lib.optionals config.services.pipewire.enable [
      {
        directory = ".config/pulse";
        mode = "0700";
      }
      {
        directory = ".local/state/wireplumber";
        mode = "0700";
      }
    ];
  };
}
