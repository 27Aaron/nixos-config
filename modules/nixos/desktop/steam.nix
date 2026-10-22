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

    # 沒有 SDDM 時,Steam 的「切換到桌面」改呼叫 steamos-session-select,而 Jovian
    # 只提供走 SDDM 的 holo-session-select,畫面因此卡住。這裡停掉遊戲模式的 target,
    # start-gamescope-session 隨之結束,greetd 回到 tuigreet。見 WORKAROUNDS.md 的 WA-019。
    # 遊戲模式的 steam-launcher 寫死 jovianPackages.steam,programs.steam.extraPackages
    # 碰不到它,所以改覆寫套件本身;mkAfter 讓這個 overlay 排在 Jovian 的之後。
    nixpkgs.overlays = lib.mkAfter [
      (final: prev: {
        jovianPackages = prev.jovianPackages.overrideScope (
          _: p: {
            steam = p.steam.override {
              extraPkgs = _: [
                (final.writeShellScriptBin "steamos-session-select" ''
                  exec ${lib.getExe' final.systemd "systemctl"} --user stop gamescope-session.target
                '')
              ];
            };
          }
        );
      })
    ];

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
