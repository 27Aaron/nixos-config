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

  vinput = if cfg.lite then packages.fcitx5-vinput-lite else packages.fcitx5-vinput;
in
{
  options.desktop'.vinput = {
    enable = lib.mkEnableOption "Fcitx5 Vinput voice input";

    lite = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use the lite build: no local ASR model, recognition runs in the cloud.";
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

    # addon 只載入外掛,執行檔另外放進 PATH。
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

        # 命令列辨識器不看 LD_LIBRARY_PATH,找不到 libopus 就會退出。
        Environment = "VINPUT_ASR_LIBOPUS_PATH=${lib.getLib pkgs.libopus}/lib/libopus.so";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    preservation'.user.directories = [
      {
        directory = ".config/vinput";
        mode = "0700";
      }
      ".local/share/vinput"

      # 登入憑證(DoubaoIME credentials.json)存在 cache 目錄,需要保留。
      {
        directory = ".cache/vinput";
        mode = "0700";
      }
    ];
  };
}
