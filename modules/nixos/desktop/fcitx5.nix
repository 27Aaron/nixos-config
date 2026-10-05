{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.fcitx5;
in
{
  options.desktop'.fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 input method with Rime";
  };

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          # Input support for GTK applications.
          fcitx5-gtk
          (fcitx5-rime.override {
            # rime-ice ships the schema and dictionaries as a reproducible
            # package; unlike wanxiang it needs no separately pinned model.
            rimeDataPkgs = [ rime-ice ];
          })
        ];
      };
    };

    # Fcitx5 rewrites this file when input methods change at runtime, so force
    # the declarative profile back on every Home Manager activation.
    hm'.xdg.configFile."fcitx5/profile" = {
      force = true;
      text = ''
        [Groups/0]
        # Group Name
        Name=Default
        # Layout
        Default Layout=us
        # Default Input Method
        DefaultIM=rime

        [Groups/0/Items/0]
        # Name
        Name=keyboard-us
        # Layout
        Layout=

        [Groups/0/Items/1]
        # Name
        Name=rime
        # Layout
        Layout=

        [GroupOrder]
        0=Default
      '';
    };

    # Rime starts on rime-ice's schema instead of the built-in default.
    hm'.xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: rime_ice_suggestion:/
        schema_list:
          - schema: rime_ice
    '';

    preservation'.user.directories = [
      ".config/fcitx5"
      ".local/share/fcitx5"
    ];
  };
}
