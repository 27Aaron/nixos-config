{ inputs, pkgs, ... }:
let
  nagram = inputs.nagram.packages.${pkgs.stdenv.hostPlatform.system}.nagram-desktop;

  # 發行版二進位自帶的 libxkbcommon 只找 /usr/share/X11/xkb,這條路徑在
  # NixOS 不存在,找不到會在 Wayland 回呼裡段錯誤。
  # 服務檔也要改指向包裝後的執行檔,否則 DBusActivatable 會繞過它。
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
