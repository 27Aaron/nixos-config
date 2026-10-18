{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.vinput;
  vinput = inputs.fcitx5-vinput.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-vinput;
in
{
  options.desktop'.vinput = {
    enable = lib.mkEnableOption "Fcitx5 Vinput voice input";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.desktop'.fcitx5.enable;
        message = "desktop'.vinput.enable requires desktop'.fcitx5.enable";
      }
    ];

    environment.systemPackages = [ vinput ];

    # 插件本體由 fcitx5 的 addon 包裝載入;daemon 與 CLI 仍要在 PATH 上。
    i18n.inputMethod.fcitx5.addons = [ vinput ];

    # 跟著圖形工作階段走。不注入密鑰檔:預設走本地 sherpa-onnx,
    # 還沒下載模型時 daemon 仍會起來,只是無法轉寫。
    hm'.systemd.user.services.vinput-daemon = {
      Unit = {
        Description = "Fcitx5 Vinput voice input daemon";
        After = [ "pipewire.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.fcitx.Vinput";
        ExecStart = lib.getExe' vinput "vinput-daemon";
        Restart = "on-failure";
        RestartSec = 3;

        # 豆包這類命令行識別器用 ctypes.util.find_library("opus")，
        # 不看 daemon 包裝器帶上的 LD_LIBRARY_PATH，找不到就直接退出。
        Environment = "VINPUT_ASR_LIBOPUS_PATH=${lib.getLib pkgs.libopus}/lib/libopus.so";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # 模型與 daemon 自己寫的 config.json。tmpfs 根目錄不保留這兩處的話,
    # 每次重開機都要重新下載模型。
    preservation'.user.directories = [
      {
        directory = ".config/vinput";
        mode = "0700";
      }
      ".local/share/vinput"
    ];
  };
}
