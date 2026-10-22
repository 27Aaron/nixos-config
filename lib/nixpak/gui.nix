{
  config,
  lib,
  sloth,
  ...
}:
let
  inherit (config.flatpak) appId;
  runtime = path: sloth.concat' sloth.runtimeDir path;
in
{
  # 程式只看得到過濾後的 D-Bus 代理:systemd 使用者服務、鑰匙圈等未列出的
  # 服務都碰不到,否則沙箱內的程式可以請 systemd 在外面執行指令。
  dbus.policies = {
    ${appId} = "own";
    "${appId}.*" = "own";
    "org.freedesktop.DBus" = "talk";
    "ca.desrt.dconf" = "talk";
    "org.freedesktop.Notifications" = "talk";
    "org.kde.StatusNotifierWatcher" = "talk";
    # 檔案選擇器、開啟連結、深淺色設定都經過 portal;截圖、相機這類敏感操作
    # 由 portal 詢問使用者。
    "org.freedesktop.portal.Desktop" = "talk";
    "org.freedesktop.portal.Documents" = "talk";
    "org.freedesktop.portal.Fcitx" = "talk";
    "org.freedesktop.portal.Fcitx.*" = "talk";
    "org.a11y.Bus" = "see";
  }
  # 系統匣圖示以 StatusNotifierItem-<PID>-<n> 註冊,沙箱內的 PID 很小。
  // lib.listToAttrs (
    map (pid: lib.nameValuePair "org.kde.StatusNotifierItem-${toString pid}-1" "own") (lib.range 2 29)
  );

  gpu.enable = true;

  bubblewrap = {
    network = lib.mkDefault false;

    # FHS 環境會在 /tmp/.X11-unix 掛 tmpfs,/tmp 必須存在。
    tmpfs = [ "/tmp" ];

    bind.rw = [
      # libpulse 連線前會在這個目錄 mkdir 與 chmod。
      (runtime "/pulse")
      # 從檔案選擇器挑的檔案經 document portal 出現在這裡。
      (runtime "/doc")
      (sloth.concat' sloth.xdgCacheHome "/fontconfig")
      (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache")
    ];

    # 只掛需要的 socket,不掛整個 $XDG_RUNTIME_DIR:裡面還有 niri 的控制
    # socket(可執行任意程式)、ssh-agent 與 GPG agent。
    bind.ro = [
      (sloth.concat [
        sloth.runtimeDir
        "/"
        (sloth.env "WAYLAND_DISPLAY")
      ])
      (runtime "/pipewire-0")
      "/etc/fonts"
      "/etc/localtime"
      "/etc/zoneinfo"
      (sloth.concat' sloth.xdgConfigHome "/fontconfig")
      (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
      (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
    ];

    bind.dev = [ "/dev/shm" ];
  };
}
