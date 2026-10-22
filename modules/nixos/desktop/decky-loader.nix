{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.desktop'.decky-loader;
in
{
  options.desktop'.decky-loader = {
    enable = lib.mkEnableOption "Decky Loader, the plugin loader for Steam's gaming mode";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.desktop'.steam.enable;
        message = "desktop'.decky-loader.enable requires desktop'.steam.enable";
      }
    ];

    # 載入器本身以 root 執行,外掛降權為 decky 帳號;外掛從 Decky 商店於執行時下載,
    # 標記 root 的外掛仍以 root 執行。見 WORKAROUNDS.md 的 WA-020。
    jovian.decky-loader.enable = true;

    # Decky 經由 Steam 的 CEF 遠端除錯埠(localhost:8080)注入前端,Steam 只在旗標檔
    # 存在時開啟該埠。~/.steam/steam 是指向 .local/share/Steam 的連結,直接寫入實際路徑。
    systemd.user.tmpfiles.users.${vars.username}.rules = [
      "f %h/.local/share/Steam/.cef-enable-remote-debugging 0644 - - -"
    ];

    # 外掛、外掛設定與資料都在這裡;Jovian 的服務每次啟動都會 chown 給 decky。
    preservation'.os.directories = [
      {
        directory = config.jovian.decky-loader.stateDir;
        user = config.jovian.decky-loader.user;
        group = config.jovian.decky-loader.user;
        mode = "0700";
      }
    ];
  };
}
