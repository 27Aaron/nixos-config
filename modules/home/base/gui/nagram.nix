{ inputs, pkgs, ... }:
let
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
  home.packages = [ nagram-desktop ];

  # 工作階段與設定,含 tdata。
  persist'.directories = [ ".local/share/NagramDesktop" ];
}
