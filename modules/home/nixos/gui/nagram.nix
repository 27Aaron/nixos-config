{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui'.nagram;

  nagram = inputs.nagram.packages.${pkgs.stdenv.hostPlatform.system}.nagram-desktop;

  # 上游二進位內建的 libxkbcommon 只找 /usr/share/X11/xkb,在 NixOS 上會於
  # Wayland 回呼中段錯誤,因此包裝並指定 XKB_CONFIG_ROOT。D-Bus 服務檔也要
  # 指向包裝後的執行檔,否則 DBusActivatable 會繞過包裝。
  nagram-desktop = pkgs.symlinkJoin {
    name = "nagram-desktop-wrapped";
    paths = [ nagram ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/Nagram \
        --set XKB_CONFIG_ROOT ${pkgs.xkeyboard-config}/share/X11/xkb

      service=$out/share/dbus-1/services/xyz.nextalone.nagram.desktop.service
      rm -f "$service"
      substitute ${nagram}/share/dbus-1/services/xyz.nextalone.nagram.desktop.service "$service" \
        --replace-fail ${nagram}/bin/Nagram $out/bin/Nagram
    '';
  };
in
{
  options.gui'.nagram.enable = lib.mkEnableOption "the Nagram Telegram client";

  config = lib.mkIf cfg.enable {
    home.packages = [ nagram-desktop ];

    # 工作階段與設定;tdata 等同帳號登入權限。
    persist'.directories = [
      {
        directory = ".local/share/NagramDesktop";
        mode = "0700";
      }
    ];
  };
}
