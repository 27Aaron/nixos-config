{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop'.steam;
in
{
  options.desktop'.steam = {
    enable = lib.mkEnableOption "the Steam client";
  };

  config = lib.mkIf cfg.enable {
    # 上游模組預設不開 Remote Play 與區網傳輸的防火牆埠,維持預設。
    programs.steam.enable = true;

    # Steam 本體、登入憑證與 Proton prefix 都在 .local/share/Steam;.steam 是指向它的
    # 連結與 registry.vdf。
    preservation'.user.directories = [
      {
        directory = ".local/share/Steam";
        mode = "0700";
      }
      {
        directory = ".steam";
        mode = "0700";
      }
    ];
  };
}
