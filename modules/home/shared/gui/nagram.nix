{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.nagram;

  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  # 上游內附的 libxkbcommon 只找 /usr/share/X11/xkb;見 WA-007。
  nagram = inputs.nagram.packages.${pkgs.stdenv.hostPlatform.system}.nagram-desktop.override {
    buildFHSEnv =
      args:
      pkgs.buildFHSEnv (
        args
        // {
          targetPkgs = p: args.targetPkgs p ++ [ p.xkeyboard-config ];
        }
      );
  };

  # FHS 環境本身會掛入整個家目錄與 /run,不是沙箱;包在 nixpak 裡之後,
  # 內層只看得到外層放行的路徑。其他檔案經檔案選擇器的 portal 取用。
  sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = [
          ../../../../lib/nixpak/gui.nix
          ../../../../lib/nixpak/network.nix
        ];

        app.package = nagram;
        app.binPath = "bin/Nagram";
        flatpak.appId = "xyz.nextalone.nagram.desktop";

        bubblewrap.bind.rw = [
          (sloth.mkdir (sloth.concat' sloth.xdgDataHome "/NagramDesktop"))
          # Nagram 設定裡的下載位置要指向這裡;沙箱內的家目錄是 tmpfs,存到
          # 其他路徑的檔案會在關閉後消失。
          (sloth.mkdir (sloth.concat' sloth.xdgDownloadDir "/Telegram"))
        ];
      };
  };
in
{
  options.gui.nagram.enable = lib.mkEnableOption "the Nagram Telegram client";

  config = lib.mkIf cfg.enable {
    # env 會把桌面捷徑與 D-Bus 服務檔裡的執行檔換成沙箱版本。
    home.packages = [ sandboxed.config.env ];

    # 工作階段與設定;tdata 等同帳號登入權限。
    persist.directories = lib.mkIf config.persist.enable [
      {
        directory = ".local/share/NagramDesktop";
        mode = "0700";
      }
    ];
  };
}
