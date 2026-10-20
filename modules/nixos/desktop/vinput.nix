{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.vinput;
  packages = inputs.fcitx5-vinput.packages.${pkgs.stdenv.hostPlatform.system};

  # 上游只提供兩個屬性:fcitx5-vinput(含本地 ASR)與 fcitx5-vinput-lite。
  vinput = if cfg.lite then packages.fcitx5-vinput-lite else packages.fcitx5-vinput;
in
{
  options.desktop'.vinput = {
    enable = lib.mkEnableOption "Fcitx5 Vinput voice input";

    lite = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install fcitx5-vinput-lite, which upstream builds with
        -DVINPUT_ENABLE_LOCAL_ASR=OFF: no sherpa-onnx or onnxruntime, so
        recognition and rewriting happen entirely in the cloud.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.desktop'.fcitx5.enable;
        message = "desktop'.vinput.enable requires desktop'.fcitx5.enable";
      }
    ];

    environment.systemPackages = [ vinput ];

    # addon 只載入插件，執行檔另外放進 PATH。
    i18n.inputMethod.fcitx5.addons = [ vinput ];

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

        # 命令行識別器不看 LD_LIBRARY_PATH，找不到 libopus 就會退出。
        Environment = "VINPUT_ASR_LIBOPUS_PATH=${lib.getLib pkgs.libopus}/lib/libopus.so";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # 模型與 config.json 要跨重啟保留。
    preservation'.user.directories = [
      {
        directory = ".config/vinput";
        mode = "0700";
      }
      ".local/share/vinput"
    ];
  };
}
