{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop'.noctalia;
in
{
  options.desktop'.noctalia = {
    enable = lib.mkEnableOption "Noctalia desktop shell";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };

    # Noctalia is configured from its own UI, so keep that state across
    # reboots instead of writing it declaratively.
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".config/noctalia";
        mode = "0700";
      }
      {
        directory = ".local/state/noctalia";
        mode = "0700";
      }
      {
        directory = ".local/share/noctalia";
        mode = "0700";
      }
    ];
  };
}
