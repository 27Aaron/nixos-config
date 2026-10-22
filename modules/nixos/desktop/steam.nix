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
    enable = lib.mkEnableOption "Steam with the Steam Deck gaming mode from Jovian-NixOS";
  };

  config = lib.mkIf cfg.enable {
    # 不開 autoStart:它會強制改用 SDDM,與 greetd 衝突。遊戲模式改從 tuigreet
    # 的工作階段選單或 TTY 的 start-gamescope-session 進入。它無法關閉的裝置權限、
    # polkit 規則與電源鍵設定見 WORKAROUNDS.md 的 WA-018。
    jovian.steam.enable = true;

    # SteamOS 預設值含 amd_iommu=off、audit=0 與 split_lock_mitigate=0,會抵銷
    # core/kernel-hardening.nix;zram 與 earlyoom 也與既有設定重複。
    jovian.steamos.useSteamOSConfig = false;

    # setuid 的 OLED 面板校正工具;唯一的呼叫者 galileo-mura-setup.service 只在
    # Valve Galileo(Deck OLED)上啟動,其他機器不必多一個 setuid 程式。
    security.wrappers.galileo-mura-extractor.enable = config.jovian.devices.steamdeck.enable;

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
