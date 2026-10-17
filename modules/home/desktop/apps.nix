{ inputs, pkgs, ... }:
let
  nagram = inputs.nagram.packages.${pkgs.stdenv.hostPlatform.system}.nagram-desktop;

  # 發行版二進位自帶的 libxkbcommon 只找 /usr/share/X11/xkb。
  # 上游 FHS 沒有 xkeyboard-config,NixOS 也沒有這條路徑,
  # xkb context 建立失敗後會在 Wayland 回呼裡段錯誤。
  # 桌面檔是 DBusActivatable,服務檔也要改指向這個包裝,否則從選單啟動會繞過它。
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
  home.packages = [
    pkgs.vscode
    nagram-desktop
    # 查看 GNOME 鑰匙環。
    pkgs.seahorse
  ];

  # 設定與登入態由程式自行寫入,只保留跨重啟。
  persist'.directories = [
    # VS Code 的使用者資料、擴充功能與工作區狀態。
    ".config/Code"
    ".vscode"

    # Nagram 的工作階段與設定,含 tdata。沒有舊資料時寫在這裡。
    ".local/share/NagramDesktop"
  ];
}
